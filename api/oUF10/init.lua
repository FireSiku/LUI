local _, ns = ...
ns.DF = GetServerExpansionLevel() == 9 ---@DF
if not ns.oUF then
    ns.oUF = {}
    ns.oUF.Private = {}
end