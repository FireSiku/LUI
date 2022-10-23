local _, ns = ...
ns.DF = select(4, GetBuildInfo()) > 99999 ---@DF
if not ns.oUF then
    ns.oUF = {}
    ns.oUF.Private = {}
end