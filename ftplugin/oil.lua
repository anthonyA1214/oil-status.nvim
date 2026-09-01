local ok, oil_status = pcall(require, "oil-status")
if ok then
	if not oil_status._is_configured() then
		oil_status.setup()
	else
		oil_status.refresh()
	end
end
