Simple Chat Script v0.16 documentation

SCS (SimpleChatScript) is a chat command system that is very simple to use yet quite powerful when setted up properly. It's originally written by Kollobz for Singet studio, but can be used everywhere you whant, **if Singet studio gave you permission.**

# Syntax #

SCS syntax is pretty simple:
**"string"** - string value
**123** or **123.456** - numeric value
**VariableReference** - variable reference
**(method "call")** - nested call
**<<static "method" "call">>** - static nested call

Let's take a look to each construction one by one.

First of all, call syntax. You will write all your chat commands like that:
*method* *args...*
Where:
  *method* - method wich will be called
  *args...* - arguments provided to method

# Next, argument types #
  *"string"* - string argument. Can contain absolutely anything excluding double quotes
  *1234* or *1234.56* - number argument. Can contain absolutely any number, even float

**That's all SCS argument types. Yes, there only two types of them, but actually you don't need more.**

# And the most difficult thing - nested code #
  *({method} {args...})* - nested call. It will be replaced with value returned by method after evaluation
  *<{method} {args...}>* - static nested call. It will be ignored after evaluation

Actually nested code - is a call inside other call. It's not limited by depth, so you can call a method inside a mathod inside a method...

# Some nested call tricks #

var (var "foo" "bar") "egg" - creates variable "foo" with value "bar" and then creates variable "bar" ("bar" value got from nested var call) with value "egg"

out (var "foo", "bar") - creates variable "foo" with value "bar" and then outputs it's value

# Built-in methods #
  out (ANY): NULL - sends given value to output stream
  var (STRING, ANY): REFERENCE - creates variable with given name, assigns given value to it and returns reference to it
  svar (STRING, ANY): REFERENCE - creates server (protected) variable with given name, assigns given value to it and returns reference to it