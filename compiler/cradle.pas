{--------------------------------------------------------------}
program Cradle;
{--------------------------------------------------------------}
{ Constant Declarations }
const TAB = ^I;
const CR = ^M;
{--------------------------------------------------------------}
{ Variable Declarations }
var Look: char;
{ Lookahead Character }
{--------------------------------------------------------------}
{ Read New Character From Input Stream }
procedure GetChar;
begin
    Read(Look);
end;
{--------------------------------------------------------------}
{ Report an Error }
procedure Error(s: string);
begin
    WriteLn;
    WriteLn(^G, 'Error: ', s, '.');
end;
{--------------------------------------------------------------}
{ Report Error and Halt }
procedure Abort(s: string);
begin
    Error(s);
Halt;
end;
{--------------------------------------------------------------}
{ Report What Was Expected }
procedure Expected(s: string);
begin
    Abort(s + ' Expected');
end;
{--------------------------------------------------------------}
{ Match a Specific Input Character }
procedure Match(x: char);
begin
    if Look = x then GetChar
    else Expected('''' + x + '''');
end;
{--------------------------------------------------------------}
{ Recognize an Alpha Character }
function IsAlpha(c: char): boolean;
begin
    IsAlpha := upcase(c) in ['A'..'Z'];
end;
{--------------------------------------------------------------}
{ Recognize a Decimal Digit }
function IsDigit(c: char): boolean;
begin
    IsDigit := c in ['0'..'9'];
end;
{--------------------------------------------------------------}
{ Get an Identifier }
function GetName: char;
begin
    if not IsAlpha(Look) then Expected('Name');
    GetName := UpCase(Look);
    GetChar;
end;
{--------------------------------------------------------------}
{ Get a Number }
function GetNum: char;
begin
    if not IsDigit(Look) then Expected('Integer');
    GetNum := Look;
    GetChar;
end;
{--------------------------------------------------------------}
{ Output a String with Tab }
procedure Emit(s: string);
begin
    Write(TAB, s);
end;
{--------------------------------------------------------------}
{ Output a String with Tab and CRLF }
procedure EmitLn(s: string);
begin
    Emit(s);
    WriteLn;
end;
{---------------------------------------------------------------}
{--------------------------------------------------------------}
{ Initialize }
procedure Init;
begin
    GetChar;
end;
{---------------------------------------------------------------}
{ Parse and Translate an Identifier }
procedure Ident;
var Name: char;
begin
    Name := GetName;
    if Look = '(' then begin
        Match('(');
        Match(')');
        EmitLn('BSR ' + Name);
        end
    else
        EmitLn('MOVE ' + Name + '(PC),D0')
end;
{---------------------------------------------------------------}
{ Parse and Translate a Math Factor }
procedure Expression; Forward;
procedure Factor;
begin
    if Look = '(' then begin
        Match('(');
        Expression;
        Match(')');
        end
    else if IsAlpha(Look) then 
        Ident
    else 
        EmitLn('MOVE #' + GetNum + ',D0');
end;
{--------------------------------------------------------------}
{ Recognize and Translate a Multiply }
procedure Multiply;
begin
    Match('*');
    Factor;
    EmitLn('MULS (SP)+,D0');
end;
{-------------------------------------------------------------}
{ Recognize and Translate a Divide }
procedure Divide;
begin
    Match('/');
    Factor;
    EmitLn('MOVE (SP)+,D1');
    EmitLn('DIVS D1,D0');
end;
{---------------------------------------------------------------}
{ Parse and Translate a Math Term }
procedure Term;
begin
    Factor;
    while Look in ['*', '/'] do begin
        EmitLn('MOVE D0,-(SP)');
        case Look of
        '*': Multiply;
        '/': Divide;
        else Expected('Mulop');
        end;
    end;
end;
{--------------------------------------------------------------}
{ Recognize and Translate an Add }
procedure Add;
begin
    Match('+');
    Term;
    EmitLn('ADD (SP)+,D0');
end;
{-------------------------------------------------------------}
{ Recognize and Translate a Subtract }
procedure Subtract;
begin
    Match('-');
    Term;
    EmitLn('SUB (SP)+,D0');
    EmitLn('NEG D0');
end;
{---------------------------------------------------------------}
{ Recognize an Addop }
{ refactored the addop check into a function}
// fermato a pag.23
function IsAddop(c: char): boolean;
begin
    IsAddop := c in ['+', '-'];
end;
{--------------------------------------------------------------}
{ Parse and Translate an Expression }
procedure Expression;
begin
    if IsAddop(Look) then
        EmitLn('CLR D0')
    else
        Term;
    while IsAddop(Look) do begin
        EmitLn('MOVE D0,-(SP)');
        case Look of
            '+': Add;
            '-': Subtract;
        else Expected('Addop');
        end;
    end;
end;
{--------------------------------------------------------------}
{ Main Program }
begin
    Init;
    Expression;
    if Look <> CR then Expected('Newline');
end.
{--------------------------------------------------------------}