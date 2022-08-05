# SCS v1.16 creator documentation #

This guide created for Roblox creators who wants to use SCS in their own projects

# SCS usage #

SCS is made as ModuleScript to import it from everywhere
To use it you must put
```
local SCS = require(PathToSCSScript:WaitForChild("SCS")
```
To header of your script<br>
SCS doesn't parses command prefix, so you need to remove it by yourself<br>
To run SCS expression you could use **EvaluateCommand** method:
```
SCS.EvaluateCommand({code})
```
Then, I recommend you to clear return stack with **FlushReturnStack** method:
```
SCS.EvaluateCommand({code})
SCS.FlushReturnStack()
```

That's all you actually need to run SCS expression

# SCS API #

This part is about SCS API

SCS API provides you tools to interact with SCS environment<br>
For example **EvaluateCommand** and **FlushReturnStack** methods that were shown below
are part of SCS API

### SCS API methods:<br>

*EvaluateCommand(command: string): nil*<br>
> evaluates given SCS expression<br>
> Exceptions:<br>
>	SCS.SyntaxError - thrown if any syntax error occured<br>
>	SCS.ReferenceException - thrown if got reference to non-existing variable
>	SCS.EvaluationException - thrown if nested call returned nil<br>

*LuaEval(value: any): SCS.Token*
> converts lua value to **Token**. Tokens are used to store variable values and while parsing<br>
> Exceptions:<br>
>	SCS.ConvertationException - thrown if no way to convert value to SCS value

*RegisterMethod(method: SCS.MethodDelegate): boolean*
> registers custom SCS method from delegate<br>
> Remarks:<br>
>	returns *true* if succeeded, else *false*<br>

*SetVar(name: string, vlaue: any): nil*
> sets value of variable with name *name* to *value*, or creates new variable

*SetVarT(name: string, value: SCS.Token): nil*
> sets value of variable with name *name* to *value*, or creates new variable. Works faster than *SetVar* but requires *SCS.Token* as value

*SetSVar(name: string, value: any): nil*
> sets value of server variable with name *name* to *value*, or creates new variable

*SetSVarT(name: string, value: SCS.Token): nil*
> sets value of server variable with name *name* to *value*, or creates new variable. Works faster than *SetSVar* but requires *SCS.Token* as value

*GetVar(name: string): any*
> returns value of variable with name *name*

*GetVarT(name: string): SCS.Token*
> returns value of variable with name *name* as *SCS.Token*. Works faster than *GetVar*

*GetSVar(name: string): any*
> returns value of server variable with name *name*

*GetSVarT(name: string): SCS.Token*
> returns value of server variable with name *name* as *SCS.Token*. Works faster than *GetSVar*

*MakeRef(var: string): SCS.Token(REFERENCE)*
> returns *SCS.Token* that referes to variable *var*

*FlushReturnStack(): nil*
> clears return stack

*GetReturnStack(): table(Token...)*
> returns return stack

### And also tables and classes:<br>

*MethodDelegate*
> class that delegates functions to SCS<br>
> Constructor:
> > *nm: string* - name of method, that should be written to call it<br>
> > *funct: function* - function that would be called<br>
> > *arg: table(ARGUMENT_TYPE...)* - expected arguments to call method<br>
> > *accessLvl: number* - access level of method. Higher - less people can call it<br>
> Usage:<br>
> > Pass functions through *RegisterMethod*<br>
> Example:<br>
> > local delegate = SCS.MethodDelegate:new("hello", function(args) print("Hello, "..args[1]) end, {SCS.ArgTypes.STRING}, 0)<br>

*ArgTypes*
> table that contains all the variable types.<br>
> Values:
> > *STRING* - string argument<br>
> > *NUMBER* - number argument<br>
> > *ANY* - any of these<br>

# Snippets and recomendation #

**Creating your own method:**
1. function must take table *args* that will contain call arguments as argument
2. if function returns anything, it should return it as *SCS.Token*
3. method names should be written in camelCase

Example:
```
local delegate = SCS.MethodDelegate:new("exampleMethod", function(args) return SCS.LuaEval(args[1] + args[2]) end, {SCS.ArgTypes.NUMBER, SCS.ArgTypes.NUMBER}, 0)
SCS.RegisterMethod(delegate)
```