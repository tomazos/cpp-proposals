    Doc no: Dnnnn
    Date: 2013-11-16
    Project: Programming Language C++, Evolution Working Group
    Reply-to: Andrew Tomazos <andrewtomazos@gmail.com>

# Safe Switch

## History: BCPL -> B -> C -> C++

The switch statement as defined in the current C++14 draft was inherited unaltered from C which in turn was inherited unaltered from the B programming language. It was designed in 1969 by Ken Thompson, the author of B, under influence from the `switchon` statement in BCPL.  A BCPL `switchon` statement looks like this:

    switchon i into
    [
         case 0: x = 1; endcase
         case 1: x = 2;
         case 5: x = x + 100; docase 0
         default: x = 0; endcase
    ]

Notice that `endcase` is used instead of `break`, notice that `case 1` has an implicit fallthrough to case 5, and notice the `docase 0` with means `goto case 0`.  The `docase` / `goto case` semantic was dropped in B.

The 1969 switch statement in B is exactly the same as the one in C++14:

    switch (i)
    {
    case 0: foo: x = 1; break;
    case 1: x = 2;
    case 5: x = x + 100; goto foo;
    default: x = 0; break;
    }

Notice that a label `foo` had to be invented to implement `docase 0`.  Also notice `break` is shared between switch and iteration statements.  `continue` binds only to iteration statements.

Research (citation needed) has shown that in 97% of modern day usage in C++ of the switch statement, cases are terminated with `break`.

## Motivation

The switch statement has several design flaws that lead to bugs.

The first and foremost is the accidental fallthrough bug.  The programmer forgets to terminate a case with break, and the following case is executed accidentally:

    switch (x)
    {
    case a:
         if (y)
         {
             f();
             break;
         }
         
         // accidental or intentional fallthrough when y is false?
    case b:
         g();
    }

Because implicit fallthrough is a legacy feature of the switch statement, and is used in approximately 3% of cases intentionally, it is not possible for the implementation to distinguish between accidental fallthrough and intentional fallthrough.

When accidental fallthrough does occur, it leads to the most expensive kind of logic bug - where well-formed reasonable-sounding code (the body of the following case) is silently unwantedly executed in addition to the correct code, causing subtle fail-slow misbehaviour at a distance at run-time.  The effects are even worse than accidentally using the wrong member of a union or accessing undefined memory.  In those cases at least you usually get garbage, with accidental fallthrough you get something logically reasonable like being out-by-one or simply the wrong answer claimed as correct.

The second problem is the same as mixing labels/goto and declaration statements.  Because the switch is followed by a simple statement, and the cases are structured as labels, the scope of the statement is potentially (and usually) shared between all cases.  The switch is in effect a goto which can reach passed an initialization (which can include a constructor).  This can lead to use of variables in uninitilized state.

    switch (x)
    {
    case a:
         Obj foo = bar;
         break;
         
    case b:
         foo.f(); // foo uninitialized when case b
    }

This is not as serious as accidental fallthrough, because this can be caught by tooling, and causes the programmer to wrap the case in a compound statement.  But we may as well fix it as well while we are here.

The third problem is that as for labels, cases can potentially be used in sub-scopes.  While there are some use cases for this, such as "Duff's Device":

    void send(int* to, int* from, int count)
    {
        int n = (count + 7) / 8;
        switch(count % 8) {
        case 0: do {    *to = *from++;
        case 7:         *to = *from++;
        case 6:         *to = *from++;
        case 5:         *to = *from++;
        case 4:         *to = *from++;
        case 3:         *to = *from++;
        case 2:         *to = *from++;
        case 1:         *to = *from++;
                } while(--n > 0);
        }
    }

it breaks the atomicity of the separate cases.  While a new safe switch statement should allow the expression of such an algorithm resulting in an equally efficient program, it doesn't necessarily allow it to be expressed so tersely, given that the robustness of the 97% use is more important than the corner case duff's-device-style usage.

## Design Goals

We propose to add a new safer version of the switch statement, called a Safe Switch.  This entails the introduction of a new keyword `safe_switch`.

The use cases of a Safe Switch should be a superset of the use cases of the existing switch.  That is, all existing uses of switch should be expressible with a Safe Switch and produce equally efficient code.

The intention is that in new code `safe_switch` should be recommended to completely replace use of `switch`, in much the same way as the C++ `foo_cast` family of keywords replace C-style casts.

Furthermore, for the existing 97% of uses, the syntax and semantics of a safe switch statement should be the same as an existing switch.

## Description

For the 97% of existing switch use, without fallthrough, without declaration statements and without sub-scope case labels within the switch statement, the syntax and semantics remain identical apart from the change of keyword.

So this:

    switch (foo)
    {
    case bar:
    case baz:
        i = x + y;
        break;
    
    case qux:
        i *= 2;
    }

Can be changed to this:

    safe_switch (foo)
    {
    case bar:
    case baz:
        i = x + y;
        break;
    
    case qux:
        i *= 2;
    }

and the behaviour of the resulting program is identical.

The first difference is minor.  The sub-statement must be a compound statement.  The vast majority of programmers don't even know that it is possible to write a switch statement without a compound statement:

	int main()
	{
	        int wtf = 2;
	
	        switch (wtf)
	            wtf++; // currently ok
	                
	        safe_switch (wtf)
	        	wtf++; // error
	}

and there are only very minor use cases for non-compound switch sub-statements and they have well-known and equally efficient alternatives.

The second difference is that the compound statement must start with a case or default label:

    safe_switch (x)
    {
        y++; // error
    case 2:
        z++;
    }

The statement is unreachable anyway, so there is no clear use case.

The third difference is that case labels associated with a `safe_switch` must appear at the outermost scope of the switch statement:

   void send(int* to, int* from, int count)
   {
        int n = (count + 7) / 8;
        safe_switch(count % 8) {
        case 0: do {    *to = *from++;
        case 7:         *to = *from++; // error case not at outermost scope
        case 6:         *to = *from++;
        case 5:         *to = *from++;
        case 4:         *to = *from++;
        case 3:         *to = *from++;
        case 2:         *to = *from++;
        case 1:         *to = *from++;
                } while(--n > 0);
        }
    }

The compound sub-statement of a safe switch is parsed as a sequence of what we call case-statements.  A case-statement begins with a case-head-seq, which consists of one or more case labels (including default as a possible label).  This is followed by one or more statements (possibly including the empty statement `;`) which consitute the case-body:

    safe-switch-statement:
        safe_switch ( condition) safe-switch-body
        
    safe-switch-body:
        { case-statement-seq }

    case-statement-seq:
        case-statement
        case-statement-seq case-statement

    case-statement:
        case-head-seq case-body
    
    case-head-seq:
        case-head
        case-head-seq case-head
    
    case-head:
        case constant-expression :
        default :

    case-body:
        statement-seq

A statement in a case-body may not contain a non-nested case-head (that would start a new case statement).

Each case-statement in a safe switch introduces a new scope.  It is as if each case body was surrounded by a compound statement:

So this:

    safe_switch (foo)
    {
    case bar:
    case baz:
        i = x + y;
        break;
    
    case qux:
        i *= 2;
    }

Is as if this:

    safe_switch (foo)
    {
    case bar:
    case baz:
        {
            i = x + y;
            break;
        }
        
    case qux:
        {
            i *= 2;
        }
    }
 
And consequently this is ill-formed:

    safe_switch (x)
    {
    case a:
         Obj foo = bar;
         break;
         
    case b:
         foo.f(); // foo not found
    } 

`safe_switch` places a restriction on the flow of logic.  If it is possible to exit the case scope by flowing off the end, the program is ill-formed.  Implementations must detect and reject such code:

    safe_switch (foo)
    {
    case bar:
    case baz:
        i = x + y;

        // ill-formed: no implicit fallthrough
    case qux:
        i *= 2;
    }

To support fallthrough in a safe explicit way, we also propose to add a new kind of statement called the _goto case statement_.  This has the similar semantics as the BCPL `docase expr` construct, and the `goto case` statement from C# that has the same syntax.

    goto-case-statement:
        goto case constant-expression;
        goto default;

The constant-expression in a goto case statement is evaluated in the same way as the constant-expression in a case label.  For the first form `goto case expr`, if there does not exist a case label in the smallest enclosing switch statement with the same value, the program is ill-formed.  Likewise for `goto default`, if there does not exist a case statement with one of its `case-heads` as `default:`, the program is ill-formed.

Note, the new goto-case-statement works for the old "unsafe" switches as well as `safe_switch`.  It simply jumps to the corresponding label as you would expect in such cases.

## Technical Specifications

TODO

## Design Log

The proposal started as an idea from Kevin Gran??? to add a new syntax with an implicit break, rather than implicit fallthrough.  While removing implicit fallthrough is a valuable goal, it was felt by the proposal author that having the new syntax of `safe_switch` match the existing switch syntax that has been used for 40 years is more important than saving a little typing.  So `break` retains its usual semantics under this proposal.

The idea of addressing the scope issue was contributed by David Krauss.

Richard Smith mentioned the existing practice of a global no implicit fallthrough warning in clang and the `[[clang:fallthrough]]` attribute to suppress it.  It was felt that a global setting to change the semantics of the existing switch statement was not a satisfying solution, as it would require updating the 3% of cases in which implicit fallthrough is used intentionally in the huge amount of exisiting code.  A global warning would require updating all that old code in order to integrate it with new code. 

The idea of adding a `[[fallthrough]]` attribute statement that explicitly allowed fallthrough was considered, and early C# versions and current Go language use such a semantic, but it was felt that reimplementing the BCPL "docase" semantic was the more general approach.  Given the structure of a `safe_switch`, and connections between the case statements allow the optimizer to safely reorder the cases - as they are atomically separate.   This is the same as what C# does today, and allows the case statements to be used in a coroutine design pattern that may be useful for some advanced use cases.  These are refered to as "looping constructs" in the BCPL manual.
