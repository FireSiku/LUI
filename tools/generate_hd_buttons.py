#!/usr/bin/env python3
"""Draw LUI's 47 legacy button assets afresh at 8x resolution.

Requires Pillow and NumPy. No source pixels are upscaled: the source images are
read only for filename, canvas size, and occupied-region metadata. Native UV
layouts are retained. Run: python generate_hd_buttons.py ORIGINAL_DIR OUTPUT_DIR
"""
import argparse, hashlib, json, math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

SCALE = 8
BG = (35, 38, 43, 255)
MATERIAL_BRIGHTNESS = .90

def material(color):
    """Slightly darker face/bevel only; preserve alpha and symbol colors."""
    return tuple(round(c * MATERIAL_BRIGHTNESS) for c in color[:3]) + color[3:]

class Canvas:
    def __init__(self, size, opaque=False):
        self.size=size; self.w,self.h=size; self.scale=min(SCALE,1024/max(size))
        self.im=Image.new('RGBA',(round(self.w*self.scale),round(self.h*self.scale)),(0,0,0,255 if opaque else 0))
    def box(self,b,color):
        s=self.scale; b=tuple(round(v*s) for v in b)
        ImageDraw.Draw(self.im).rectangle((b[0],b[1],b[2]-1,b[3]-1),fill=color)
    def line(self,points,color,width=1):
        s=self.scale; ImageDraw.Draw(self.im).line([(round(x*s),round(y*s)) for x,y in points],fill=color,width=max(1,round(width*s)),joint='curve')
    def poly(self,points,color):
        s=self.scale; ImageDraw.Draw(self.im).polygon([(round(x*s),round(y*s)) for x,y in points],fill=color)
    def gradient(self,b,top,bottom):
        s=self.scale;x0,y0,x1,y1=(round(v*s) for v in b); w,h=x1-x0,y1-y0
        if w<=0 or h<=0:return
        t=np.linspace(0,1,h)[:,None,None]; a=np.array(top)[None,None,:]; z=np.array(bottom)[None,None,:]
        px=np.repeat(np.uint8(np.rint(a*(1-t)+z*t)),w,axis=1)
        self.im.paste(Image.fromarray(px,'RGBA'),(x0,y0))
    def face(self,b,state='Up'):
        x,y,r,d=b
        down=state in ('Down','Disabled-Down');disabled='Disabled' in state
        self.box(b,material((8,9,9,255)))
        top,bot=((31,33,33,255),(48,50,50,255)) if down else ((77,80,79,255),(30,32,32,255))
        if disabled:top,bot=(44,46,45,255),(32,34,33,255)
        self.gradient((x+.65,y+.65,r-.65,d-.65),material(top),material(bot))
        # Straight one-native-pixel bevel. Kept quiet to avoid a plastic look.
        bright=material((99,102,98,255) if not disabled else (63,66,63,255))
        self.box((x+.6,y+.6,r-.6,y+1.15),material((12,13,13,255)) if down else bright)
        self.box((x+.6,d-1.15,r-.6,d-.6),bright if down else material((13,14,14,255)))
        self.box((x+.6,y+1.15,x+1,d-1.15),material((47,50,48,255)))
        self.box((r-1,y+1.15,r-.6,d-1.15),material((17,18,18,255)))
    def glyph(self,b,role,state='Up'):
        x,y,r,d=b;cx=(x+r)/2;cy=(y+d)/2;w=r-x;h=d-y
        disabled='Disabled' in state
        ink=(121,122,116,255) if disabled else ((191,174,85,255) if state=='Down' else (229,211,112,255))
        if role in ('plus','minus','close'):ink=(119,123,121,255) if disabled else (213,217,209,255)
        lw=max(.9,min(w,h)*.085)
        if role in ('plus','minus'):
            a=w*.235;self.line([(cx-a,cy),(cx+a,cy)],ink,lw)
            if role=='plus':self.line([(cx,cy-h*.235),(cx,cy+h*.235)],ink,lw)
        elif role=='close':
            a=min(w,h)*.215;self.line([(cx-a,cy-a),(cx+a,cy+a)],ink,lw);self.line([(cx-a,cy+a),(cx+a,cy-a)],ink,lw)
        elif role in ('up','down'):
            a=w*.23;dy=h*.16;sy=-1 if role=='up' else 1
            self.poly([(cx-a,cy-sy*dy),(cx+a,cy-sy*dy),(cx,cy+sy*dy*1.45)],ink)
        elif role in ('left','right'):
            a=h*.245;sgn=1 if role=='right' else -1
            self.poly([(cx-sgn*w*.13,cy-a),(cx-sgn*w*.13,cy+a),(cx+sgn*w*.2,cy)],ink)
        elif role in ('rotateleft','rotateright'):
            rad=min(w,h)*.22;cy+=h*.08
            pts=[(cx+rad*math.cos(t),cy+rad*math.sin(t)) for t in np.linspace(-math.pi*.15,-math.pi*1.2,80)]
            if role=='rotateright':pts=[(2*cx-a,b) for a,b in pts]
            self.line(pts,ink,lw)
            hx,hy=pts[-1]
            dx,dy=hx-pts[-2][0],hy-pts[-2][1]
            length=math.hypot(dx,dy);dx/=length;dy/=length
            # Follow the arc tangent so left/right arrows retain their meaning.
            self.poly([(hx+dx*1.6,hy+dy*1.6),
                       (hx-dx*1.4-dy*1.6,hy-dy*1.4+dx*1.6),
                       (hx-dx*1.4+dy*1.6,hy-dy*1.4-dx*1.6)],ink)
    def ring(self,b,width,top=(100,104,100,255),bottom=(30,32,32,255)):
        x,y,r,d=b
        self.gradient(b,material(top),material(bottom))
        self.box((x+width,y+width,r-width,d-width),(0,0,0,0))
        self.box((x+width-.7,y+width-.7,r-width+.7,y+width),material((10,11,11,255)))
        self.box((x+width-.7,d-width,r-width+.7,d-width+.7),material((91,94,90,255)))
    def glow(self,b,color=(100,156,224),opaque=False,ring=False):
        # Analytic smooth glow, sampled directly at final resolution.
        s=self.scale;hh,ww=self.im.height,self.im.width
        xx=(np.arange(ww)+.5)/s; yy=(np.arange(hh)+.5)/s
        X,Y=np.meshgrid(xx,yy);x,y,r,d=b
        if ring:
            inside=np.minimum.reduce([X-x,r-X,Y-y,d-Y]);amount=np.exp(-((inside-1.0)/1.15)**2)
        else:
            tx=(X-(x+r)/2)/max((r-x)/2,.001);ty=(Y-(y+d)/2)/max((d-y)/2,.001)
            amount=np.clip(1-np.maximum(np.abs(tx)**8,np.abs(ty)**3),0,1)*.58
        mask=(X>=x)&(X<r)&(Y>=y)&(Y<d);amount*=mask
        arr=np.zeros((hh,ww,4),dtype=np.uint8)
        for k,c in enumerate(color):arr[:,:,k]=np.uint8(np.rint(c*amount)) if opaque else c
        arr[:,:,3]=255 if opaque else np.uint8(np.rint(220*amount))
        self.im=Image.fromarray(arr,'RGBA')

def native_bbox(im):
    return im.getchannel('A').getbbox()

def render(name,size,bbox):
    state='Disabled-Down' if name.endswith('Disabled-Down') else name.rsplit('-',1)[-1]
    opaque=name in {'UI-ActionButton-Border','UI-CheckBox-Highlight','UI-Panel-MinimizeButton-Highlight','UI-Panel-Button-Highlight','UI-DialogBox-Button-Highlight'}
    c=Canvas(size,opaque)
    if name in ('UI-Panel-Button-Up','UI-Panel-Button-Down','UI-Panel-Button-Disabled'):
        c.face(bbox or (2,3,77,22),state)
    elif name=='UI-Panel-Button-Disabled-Down':c.face(bbox,state)
    elif name.startswith('UI-DialogBox-Button-') and state!='Highlight':c.face(bbox or (2,2,126,24),state)
    elif name in ('UI-Panel-Button-Highlight','UI-DialogBox-Button-Highlight'):
        c.glow((2,3,77,22) if 'Panel' in name else (2,2,126,24),opaque=True)
    elif name.startswith('UI-PlusButton') or name.startswith('UI-MinusButton'):
        b=bbox or (1,1,14,14);c.face(b,state);c.glyph(b,'plus' if 'Plus' in name else 'minus',state)
    elif name.startswith('UI-Panel-MinimizeButton'):
        b=bbox if state!='Highlight' and bbox else (6,7,25,25)
        if state=='Highlight':c.glow(b,opaque=True,ring=True)
        else:c.face(b,state);c.glyph(b,'close',state)
    elif name.startswith('UI-ScrollBar-Scroll'):
        b=bbox or (6,7,25,24);c.face(b,state);c.glyph(b,'down' if 'ScrollDown' in name else 'up',state)
    elif name=='UI-ScrollBar-Knob':
        c.face(bbox);x,y,r,d=bbox;cx=(x+r)/2;cy=(y+d)/2
        for dy in (-1.8,0,1.8):c.box((cx-3,cy+dy,r-5,cy+dy+.55),(102,107,102,255))
    elif name.startswith('UI-SpellbookIcon'):
        b=bbox or (4,5,27,27);c.face(b,state);c.glyph(b,'left' if 'PrevPage' in name else 'right',state)
    elif name.startswith('UI-Rotation'):
        c.face(bbox,state);c.glyph(bbox,'rotateleft' if 'RotationLeft' in name else 'rotateright',state)
    elif name.startswith('UI-CheckBox'):
        if state=='Highlight':c.glow((4,5,27,26),opaque=True,ring=True)
        else:
            b=bbox;c.face(b,state);x,y,r,d=b;c.box((x+3,y+3,r-3,d-3),material((15,17,17,230)))
            if state=='Down':
                c.box((x+1,y+1,r-1,y+1.65),(187,164,76,255));c.box((x+1,d-1.65,r-1,d-1),(187,164,76,255))
                c.box((x+1,y+1,x+1.65,d-1),(187,164,76,255));c.box((r-1.65,y+1,r-1,d-1),(187,164,76,255))
    elif name in ('ButtonHilight-Square','CheckButtonHilight'):c.glow((4,4,60,60),ring=True)
    elif name=='CheckButtonGlow':c.glow((9,9,55,55),color=(248,208,47),ring=True)
    elif name=='UI-ActionButton-Border':
        # This legacy asset is used with ADD and inherits quality/class colors.
        c.box((0,0,64,64),(0,0,0,255))
        for i in range(24):
            t=i/24;v=round(215*(1-t));c.box((14+i*.18,14+i*.18,50-i*.18,50-i*.18),(v,v,v,255))
        c.box((18.4,18.4,45.6,45.6),(0,0,0,255))
    elif name=='UI-Quickslot2':c.ring((12,12,51,51),3,top=(124,126,119,255),bottom=(42,44,41,255))
    elif name in ('UI-QuickslotGray','UI-QuickslotRed','UI-Quickslot-Depress'):
        c.ring((0,0,64,64),6,top=(33,36,34,255),bottom=(91,94,90,255))
        # Preserve the lower bevel region without a low-resolution curved mask.
        c.gradient((6,55,58,62),material((62,65,62,200)),material((114,118,112,255)))
    else:raise ValueError(name)
    return c.im

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('original',type=Path);p.add_argument('output',type=Path);p.add_argument('--contact',type=Path)
    a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);files=sorted(a.original.glob('*.blp'));meta=[];previews=[]
    for f in files:
        original=Image.open(f).convert('RGBA');bbox=native_bbox(original);im=render(f.stem,original.size,bbox);dest=a.output/(f.stem+'.tga');im.save(dest,format='TGA')
        with Image.open(dest) as check:
            check.load();assert check.mode=='RGBA';assert check.size==(original.width*SCALE,original.height*SCALE)
        meta.append({'name':f.stem,'original_size':original.size,'original_alpha_bbox':bbox,'output_size':im.size,'output_alpha_bbox':native_bbox(im),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
        previews.append((f.stem,original,im))
    (Path(__file__).resolve().parent/'hd-buttons-manifest.json').write_text(json.dumps(meta,indent=2)+'\n')
    if a.contact:
        a.contact.parent.mkdir(parents=True,exist_ok=True)
        cw,ch=480,190;sheet=Image.new('RGB',(cw*3,ch*math.ceil(len(files)/3)),BG[:3]);d=ImageDraw.Draw(sheet)
        for i,(name,old,new) in enumerate(previews):
            x=(i%3)*cw;y=(i//3)*ch;d.text((x+8,y+5),name,fill=(234,234,224));d.text((x+8,y+27),'Original',fill=(154,159,169));d.text((x+245,y+27),'Redrawn at 8x',fill=(154,159,169))
            for j,im in enumerate((old,new)):
                k=min(2,216/old.width,130/old.height);sz=(round(old.width*k),round(old.height*k));im=im.resize(sz,Image.Resampling.NEAREST if j==0 else Image.Resampling.LANCZOS)
                sheet.paste(im,(x+8+j*237,y+52),im)
        sheet.save(a.contact)
    print(json.dumps({'generated':len(meta),'output':str(a.output),'contact':str(a.contact)}))
if __name__=='__main__':main()
