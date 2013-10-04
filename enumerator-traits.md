Document number: Nnnnn=yy-nnnn (Not yet assigned)

Date: 2013-10-03

Project: 	Programming Language C++, Library Working Group

Reply-to: Andrew Tomazos <andrewtomazos@gmail.com>, Cristian Kaeser <christiankaeser87@googlemail.com>

# A Proposal to Add Enumeration Type Property Queries to the Standard Library

## Table of Contents

## Introduction

We propose to add three new Type Property Queries [meta.unary.prop.query] to the standard library as a first step to enabling library authors to build various higher-level reflection facilities for enumerators.  The queries provide compile-time access to the complete information about the enumerator list of a given enumeration - specifically how many there are, their declared order, and for each their value and identifier is.

These three queries can then be used by library authors to build higher-level enumerator reflection features.  Acceptance of this proposal does not preclude future standardization of additional higher-level queries, either in stand-alone form or as part of a larger reflection initiative.

## Motivation and Scope

Being able to inspect the enumerator list during translation is the missing common foundation in C++ of a large number of frequently asked for enumeration-related reflection facilities.

Because implementations do not currently expose the basic information about an enumerator list, implementing such facilities in a standard-compliant manner is nearly impossible.  Current workarounds involve either:

Hand-maintaining and keeping synchronized secondary entities (to the enum specifier):

    enum foo
    {
        bar,
        baz,
        qux,
    };
    
    size_t foo_enumerator_count = 3; // maintain me
    
    const char* foo_to_string(foo e) // maintain me too
    {
        switch (e)
        {
        case bar: return "bar";
        case baz: return "baz";
        case qux: return "qux";
        default: throw logic_error(...);
        }
    }
    
    foo string_to_foo(const std::string& e) // etc
    {
        ...
    };
    
or, using the preprocessor:

    BEGIN_DECL_ENUMERATION(foo)
        DECL_ENUMERATOR(bar)
        DECL_ENUMERATOR(baz)
        DECL_ENUMERATOR(qux)
    END_DECL_ENUMERATION(foo)

and then processing this construct multiple times with different macro definitions (one for the enum specifier, then another for secondary entities).

or, using a non-standard "precompiler" tool such as Qt moc to scan for the enum specifiers and then produce secondary automatically-generated translation units that are then used to implement the reflection facilities.

These are all just hacks to get at information that the compiler has readily available during translation, but does not expose.  This proposal makes a first step to correct this situation.

The intended user community of this proposal are the infrastructure-providers and framework-authors for almost every enumeration user.

The use of the proposed features is intended, as for the other Type Property Queries, to support programmers that use metaprogramming and generic programming to form higher-level constructs at compile time.

We have a complete reference implementation of the proposed feature.  It is extremely easy to implement, and for a basic implementation requires only implementing three compiler intrinsics that inspect the annotated AST of the enum specifier.  The interface is setup so that these intrinsics only need to be callable at compile-time when the properties are instantiated - and so implies no mandated run-time resources at all.  The compile-time cost is of course also zero if the properties are never instantiated.

## Impact On the Standard

The proposed feature adds three Type Property Queries in the typical form.  It requires only some minimal compiler support to implement the three queries.

No other standard library feature depends on it.

For ease of use, `std::integer_sequence` is useful to be able to map the enumerator values and/or enumerator identifiers into a pack for futher processing.  As are other current and future metaprogramming techniques/facilties, such as those applicable to using `std::get<i>(tuple)` - such as future planned literal packs.  Ease of use of the interface will improve for Type Property Queries along with general improvements in C++ metaprogramming.

As `std::enumerator_value` is an enumerator value of the enumeration type, it can be used in combination with the existing `std::underlying_type` if one wishes to convert it a value of the underlying type instead.

## Design Decisions

### Design Goals

The interface should:

- be complete (provide _all_ information about the enumerator list of _any_ enumeration type)
- be minimal and low-level
- entail no run-time cost
- entail no compile-time cost if unused
- not mandate the form of a specific lookup algorithm or data structure
- be self-contained and free of dependencies
- be usable during translation

### Design History

The proposal in its current form is the result of a merge of several separate proposals.

The first was to add a core language feature that, given an enumeration type `enum E {a, b, c}`, a construct of the form `E...` would expand to a pack of the enumerator list of `E`, that being `a, b, c`.  This could be used in the usual contexts, `braced-init-list` contexts or as template or function arguments.  This was later improved by suggesting that instead a non-type parameter pack of type `E...` would match an argument of type `E`, and instead of being ill-formed, would expand to the enumerator list of `E`.  As such a pack can be formed using the proposed primitives, and as the proposed functions are more appropriate encapsulated as a library feature, it was decided that this proposal was superior as a small library addition rather than a core language change.

The second was to add a predefined template variable, originally called `__enumerator__` in the spirit of `__func__`, but we'll call it `std::enumerator_value_to_identifer` for sake of discussion, that would return the identifier string of an enumerator based on its value.  Such a facility is trivially definable using a combination of the proposed queries.  There are several reasons it was not included in this proposal.  Consider the following enumeration types:

    enum E1 { a, b, c };  // simple 0,1,2...n-1
    enum E2 { a = 42, b = 42, c = 43 }; // ambiguous values
    enum E3 { a = 42, b = 420000 }; // sparse values
    enum E4 { a = 1 << 0, b = 1 << 1, c = 1 << 2 }; // bit sets
    enum E5 { a = 1 << 0, b = 1 << 1, c = 1 << 2, m = 0b111 }; // masks
    
There is no single best approach that can be mandated.  What shall `std::enumerator_value_to_identifier(x)` return when x is ambiguous?  Shall it return the identifier of the first enumerator to have the value?  In what order?  Shall it return a delimited string concatenated with all the identifiers of equal value?  Again, in what order?  And how shall they be delimited? Shall it return an array or `std::set` of those of equal value instead?  Shall it fail at compile-time with an ambiguity?  Shall it have an interface like `std::multimap`?  What underlying data structure or algorithm should it use to do the lookup?  Should the case of an enumeration with contiguous enumerator values that start from zero be dealt with seperately from ones with sparse values?  What about enumerations that are used as bitsets?  What about enumerations without ambiguous enumerators at all?

All the many alternative ways of answering these questions can all be built up from the proposed queries, as they provide the complete compile-time information about the enumerator list.  We note that acceptance of this proposal would not preclude future standardization of an additional facility such as `std::enumerator_value_to_identifier` if sufficiently general answers to these questions are later found.  As a first step we decided to move standardization of `std::enumerator_value_to_identifier` to a future proposal, so as not to unnecessarily delay standardization of the more general foundation primitives.

The next proposal that was considered was creating a set of higher-level reflection facilities above the proposed primitives (and leave the primitives as an implementation detail) that would be fully integrated with other standard library facilities.  It was quickly realized that, as per `std::enumerator_value_to_identifier`, there are many different use cases and different application domains and tradeoffs.  So we decided to defer such higher-level facilities to a future proposal so as not to delay the urgently needed proposed queries.  We added the design goal for this proposal that the primitives should provide complete information, but should be minimal outside of that.

We also realized that the declaration order of enumerators may be significant for some applications and so added this information for completeness to our interface.  All other orderings can be sorted from declaration order, but once declaration order is lost it cannot be recovered.

The next key design decision was identifier representation.  As per [lex] an identifier is formed during translation phase 1 by mapping the source files in source encoding in an implementation-defined manner to ISO 10646 (Unicode) characters with the constraints given in [charname.allowed] and [charname.disallowed].  Characters outside the basic source character set are then logically encoded into univeral-character-name escape sequences.  For the remainder of translation identifiers remain in this form.  String literals have any universal-character-name escape sequences decoded during translation phase 5.  Depending on the string literal prefix a string literal is then encoded into one of five character encodings.  One of these is the implementation-defined execution character encoding, three are the standard Unicode character encodings UTF-8, UTF-16 and UTF-32, and the last is a direct encoding which is effectively equivalent to UTF-32.

It was proposed to provide an interface that took as a template parameter which of the five character encodings were desired.  For minimality it was decided that such a facility should be defered for higher-level facilities and a single encoding would be provided, given that an encoded string in a constexpr array or string literal can be transcoded during translation to any other encoding anyway - so completeness remained intact.  Originally the single encoding that was considered was the implementation-defined execution encoding, but it was later realized that not all execution encodings can handle all characters (for example ASCII or Latin1), so this would violate the completeness requirement.  So it was decided to choose one of the Unicode encodings.  Implementations are already required to handle all of these, and all of them can encode all characters.  UTF-8 was selected because as an 8-bit encoding it is endianess-agnostic, unlike UTF-16 and UTF-32, and it is the most common execution encoding anyway.

Because universal-character-names escape sequences in identifiers are not logically decoded in translation phase 5, it was noted that we should add this as an explicit requirement to the identifier encoding text.

At this point we had the complete information we wanted to provide.  A list of enumerators, and for each its position in declared order, its value and its identifier encoded as described above.  The identifier should be encoded in an array of chars (UTF-8 code units) and null-terminated so that it may be used as a C string or to initialize a std::string, and that array must be defined with constexpr or be a string literal so that its elements are usable within a constant expression (such that an lvalue-to-rvalue conversion is allowed on them), so the string could be worked with during translation.

The next step was how to expose that information from the compiler during translation.  For efficient mapping from the internal compiler representation it was decided that it should be represented as a sequence in declared order.  We then considered using an array to represent such a sequence:

Either:

       enum E {a = 42, b = 42, c = 43};
       
       constexpr E enumeration_values[] = {a, b, c};
       constexpr const char* enumeration_identifiers[] = {u8"a", u8"b", u8"c"};

or

       struct enumerator_info
       {
           E value;
           const char* identifier;
       };
       
       constexpr enumerator_info[] = { {a, u8"a"}, {b, u8"b"}, {c, u8"c"} };
       
But it was decided that certain uses of such an array could entail them to require static storage, and such use would mandate relocation of the array during load-time.

What we really wanted was a way to expose pure compile-time accessors to the internal compiler data structure that holds the enumerator list, without providing a set data structure or algorithm - leaving this up to the library author, and for a later proposal for higher-level facilities.

To avoid this it was then considered to use functions:

        constexpr size_t enumerator_count();
        constexpr E enumerator_value(size_t index);
        constexpr const char* enumerator_identifier(size_t index);

The functions could then be backed by intrinsics, but for the later two if the index was out-of-bounds for certain uses would mandate run-time error handling.

So finally it was decided to make them Type Query Properties and the final interface was arrived at:

        namespace std
        {
            // number of enumerators in E
        	template<class E>
        	struct enumerator_count { constexpr size_t value; }
        	
        	// value of I'th enumerator in E
        	template<class E, size_t I>
        	struct enumerator_value { constexpr E value; }
        	
        	// identifier of I'th enumerator in E
        	template<class E, size_t I>
        	struct enumerator_identifier { constexpr char[] value; }
        };

By making the input template parameters we can allow implementations to implement them as instrinsics that access and return information directly from the internal compiler enumerator list during translation, as per other type property queries.  We added requirements that E be an enumeration type and I must be in-bounds.

## Technical Specifications

20.11.5 [meta.unary.prop.query] Type property queries

1. This sub-clause contains templates that may be used to query properties of types at compile time.

Add to Table 50 - Type property queries:

     template<class E> struct enumerator_count;
     
     An integer value representing the number of enumerators in E

     Requires: std::is_enum<E> shall be true

     --------------------------------------------
     
     template<class E, std::size_t I> struct enumerator_value;
     
     A value of type E that is the I'th enumerator of E in declared order,
     where indexing of I is zero-based.
     
     Requires: std::is_enum<E> shall be true
     Requires: I shall be nonnegative and less than enumerator_count<E>

     --------------------------------------------

     template<class E, std::size_t I> struct enumerator_identifier;

     A value of type array of char, defined with constexpr, representing
     the identifier of the I'th enumerator of E in declared order, where
     indexing of I is zero-based. The value shall be null-terminated,
     UTF-8 encoded, and have any universal-character-names decoded.
     
     Requires: std::is_enum<E> shall be true
     Requires: I shall be nonnegative and less than enumerator_count<E>
     
Add new paragraph 4:

     [Example:
     
     // In the below π is in source encoding (before translation phase 1)
     enum foo
     {
         bar,
         Baz,
         Qux = 42,
         Quux = 42,
         eπ = 96,
         f\u03C0 = 300000
     };
         
     // the following assertions hold
     static_assert(enumerator_count<foo>::value == 6);

     static_assert(enumerator_value<foo,0>::value == Bar);
     static_assert(enumerator_value<foo,1>::value == Baz);
     static_assert(enumerator_value<foo,2>::value == Qux);
     static_assert(enumerator_value<foo,3>::value == Quux);
     static_assert(enumerator_value<foo,4>::value == eπ);
     static_assert(enumerator_value<foo,5>::value == f\u03C0);
     
     assert(std::strcmp(enumerator_identifier<foo,0>::value, u8"bar") == 0);
     assert(std::strcmp(enumerator_identifier<foo,1>::value, u8"Baz") == 0);
     assert(std::strcmp(enumerator_identifier<foo,2>::value, u8"Qux") == 0);
     assert(std::strcmp(enumerator_identifier<foo,3>::value, u8"Quux") == 0);
     assert(std::strcmp(enumerator_identifier<foo,4>::value, u8"eπ") == 0);
     assert(std::strcmp(enumerator_identifier<foo,5>::value, u8"f\u03C0") == 0);
     
     // universal character names handled correctly:
     static_assert(enumerator_value<foo,4>::value == e\u03C0);
     static_assert(enumerator_value<foo,5>::value == fπ);
     assert(std::strcmp(enumerator_identifier<foo,4>::value, u8"e\u03C0") == 0);
     assert(std::strcmp(enumerator_identifier<foo,5>::value, u8"fπ") == 0);

     // constant lvalue-to-rvalue conversion on array elements ok:
     constexpr const char* str = enumerator_identifier<foo,0>::value;
     static_assert(str[0] == 'b');
     static_assert(str[1] == 'a');
     static_assert(str[2] == 'r');
     static_assert(str[3] == '\0');
     
     -- end example]

## Reference Implementation

Here is an the interface from our reference implementation:

    template<typename E>
    struct enumerator_count // number of enumerators in E
    {
        static_assert(std::is_enum<E>::value, "E not enum type");
        
        static constexpr size_t value = __enumerator_count(E);
    };
      
    template<typename E, std::size_t I>
    struct enumerator_value
    {
        static_assert(std::is_enum<E>::value, "E not enum type");
		static_assert(0 <= I && I < std::enumerator_count<E>::value, "I out-of-bounds");

        static constexpr E value = __enumerator_value(E, I);
    };
   
    template<typename E, std::size_t I>
    struct enumerator_identifier {
        static_assert(std::is_enum<E>::value, "E not enum type");
		static_assert(0 <= I && I < std::enumerator_count<E>::value, "I out-of-bounds");

        static constexpr char[] value = __enumerator_identifier(E, I);
    };

As can be seen it is a thin wrapper for three compiler intrinsics that inspect the annotated AST of the enum specifier.  These are called during translation when the templates are instantiated.

## Acknowledgements

We would like to thank David Krauss and Thiago Macieira for valuable initial feedback on this proposal.
