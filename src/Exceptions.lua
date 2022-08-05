local module = {}

module.Exception = {}

function module.Exception:new(ExcName: string): Exception
	local _exc ={
		EName = ExcName
	}
	
	function _exc:throw(message: stirng): nil
		print(
			string.format(
				"[SCS] %s: %s",
				self.EName,
				message
			)
		)
	end
	
	setmetatable(_exc, module.Exception)
	self.__index = self; return _exc
end

module.SyntaxError = module.Exception:new("SyntaxError")
module.ReferenceException = module.Exception:new("ReferenceException")
module.EvaluationException = module.Exception:new("EvaluationException")

return module
