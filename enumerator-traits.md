Document number: Nnnnn=yy-nnnn (Not yet assigned)

Date: 2013-10-03

Project: 	Programming Language C++, Library Working Group

Reply-to: Andrew Tomazos <andrewtomazos@gmail.com>, Christian Käser <christiankaeser87@googlemail.com>

# Enumerator List Property Queries

## Table of Contents

- Background
- Introduction
- Motivation and Scope
- Design Goals
- Design Log
- Technical Specifications
- Reference Implementation
- Use Cases
- Performance Issues
- Acknowledgements

## Background

An enumeration type is defined by an _enum-specifier_.  An _enum-specifier_ contains an _enumerator-list_.  An _enumerator-list_ is a sequence of zero or more _enumerator-definitions_. Each _enumerator-definition_ introduces an identifier (the name of the enumerator) and a corresponding value (either implicitly or explicitly).

## Introduction

We propose to add three Property Queries [meta.unary.prop.query] to the Metaprogramming and Type Traits Standard Library that provide compile-time access to the _enumerator-list_ of an enumeration type.

Specifically:

- `std::enumerator_list_size<E>`: the number of _enumerator-definitions_ in the _enumerator-list_ of `E`.
- `std::enumerator_identifier<E,I>`: the identifier from the `I`'th _enumerator-definition_.
- `std::enumerator_value<E,I>`: the value from the `I`'th _enumerator-definition_.

These urgently needed queries will enable metaprogrammers to implement frequently-asked-for higher-level facilities such as static checks and reflection.  Acceptance of this proposal does not preclude future standardization of such higher-level facilities.

## Motivation and Scope

Being able to inspect the _enumerator-list_ during translation is the missing common foundation in C++ of a large number of frequently-asked-for enumeration-related reflection facilities.

Because implementations do not currently expose this basic semantic information about an _enumerator-list_ to library authors, implementing such facilities parameterized by the enumeration type is currently impossible.  Current workarounds involve either:

- Hand-maintaining and keeping synchronized secondary entities/lists for each _enum-specifier_.  Prone to error and tedious.
- Wrapping the _enum-specifier_, with macros and using obscene preprocessor tricks.  This obfuscates the _enum-specifier_ to both programmers and programming tools, relies on non-standard preprocessor features and can complicate the build process.
- Implementing a "precompiler" tool such as Qt moc to scan the source for enum specifiers and then automatically-generate additional translation units.  This is a huge amount of work to implement and maintain in synchronization with the compiler, is inefficient, as it requires parsing the source twice from a separate tool, and complicates the build process.

These are all just workarounds to get at information that the compiler has readily available during translation, but does not expose.  This proposal corrects that.

The intended user community of this proposal are infrastructure-providers and framework-authors, which will enable them to provide generic tools benefitting most enumeration users.

The use of the proposed feature is intended, as for existing Metaprogramming Property Queries, to support programmers that use metaprogramming and generic programming to form higher-level constructs at compile-time.

We have a complete reference implementation of the proposed feature.  It is extremely easy to implement, and for a basic implementation requires only implementing three compiler intrinsics that inspect the annotated AST of the _enumerator-list_.  The interface is setup, as for existing meta property queries, so that these intrinsics only need to be callable at compile-time when the properties are instantiated - and so does not mandate any run-time code generation at all.  The compile-time cost should be non-exisiting if the properties are never instantiated, and as it provides direct access the internal compiler data structure the cost when instantiated is minimized.

## Impact On the Standard

The proposed feature adds three Property Queries to the Metaprogramming and Type Traits library in the typical form.  It requires only some minimal compiler support to implement the three queries.

As for all Property Queries in the Metaprogramming and Type Traits library, the proposed three Property Queries are for use by metaprogrammers at compile-time.  The current ease-of-use of these constructs is the same as, for example, `std:rank`, `std::extent`, `std::get(tuple)` and working with string literals (array of char defined with constexpr).  As C++ continues to evolve more sophisticated metaprogramming features, the proposed queries will become easier to use along with them.

As `std::enumerator_value<E,I>` is a value of enumeration type E, it can be used in combination with the existing `std::underlying_type<E>` if one wishes to convert it to a value of the underlying type instead.

`std::make_index_sequence` is also useful for ease-of-use to transform the properties into a pack or a constexpr array if so desired.

## Design Goals

Our design goals for the interface were:

- be complete (provide all semantic information about the _enumerator-list_ of any possible enumeration type)
- should provide efficient queries of the internal compiler data structure
- be minimal and low-level
- entail no run-time cost
- entail no compile-time cost if unused
- not mandate any specific lookup algorithm or data structure at runtime
- be self-contained and free of dependencies

There is a more detailed rationale and history of how they were arrived at and applied under the section Design Log below.

## Technical Specifications

__In Existing Section__ 20.11.5 [meta.unary.prop.query] Type property queries

1. This sub-clause contains templates that may be used to query properties of types at compile time.

__Add To__ Table 50 - Type property queries:

<table border="1">
	<tr>
		<td>
			<b>Template</b>
		</td>
		<td>
			<b>Value</b>
		</td>
	</tr>
	<tr>
		<td>
			<code>template&lt;class E&gt; struct enumerator_list_size;</code>
     	</td>
    	<td>
     		An integer value representing the number of enumerators in E<br/>
			<br/>
     		<i>Requires:</i> <code>std::is_enum&lt;E&gt;</code> shall be true
		</td>
	</tr>

	<tr>
  		<td>
  			<code>template&lt;class E, std::size_t I&gt; struct enumerator_identifier;</code>
  		</td>

  		<td>
  		A value of type array of char, defined with constexpr, holding<br/>
     	the identifier of the I'th enumerator of E in declared order, where<br/>
     	indexing of I is zero-based. The value shall be null-terminated,<br/>
     	UTF-8 encoded, and have any universal-character-names decoded.<br/>
     	<br/>
     	<i>Requires:</i> <code>std::is_enum&lt;E&gt;</code> shall be true<br/>
     	<i>Requires:</i> <code>I</code> shall be nonnegative and less than <code>std::enumerator_list_size&lt;E&gt;</code>
  		</td>
	</tr>

	<tr>
		<td>
     		<code>template&lt;class E, std::size_t I&gt; struct enumerator_value;</code>
		</td>
 		<td>    
     		A value of type <code>E</code> that is the <code>I</code>'th enumerator<br/>
     		of <code>E</code> in declared order, where indexing of <code>I</code> is zero-based.<br/>
			<br/>
     		<i>Requires:</i> <code>std::is_enum&lt;E&gt;</code> shall be true<br/>
     		<i>Requires:</i> <code>I</code> shall be nonnegative and less than <code>std::enumerator_list_size&lt;E&gt;</code>
  		</td>
	</tr>

</table>
     
__Add New Paragraph 4:__

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
     static_assert(enumerator_list_size<foo>::value == 6);

     assert(std::strcmp(enumerator_identifier<foo,0>::value, u8"bar") == 0);
     assert(std::strcmp(enumerator_identifier<foo,1>::value, u8"Baz") == 0);
     assert(std::strcmp(enumerator_identifier<foo,2>::value, u8"Qux") == 0);
     assert(std::strcmp(enumerator_identifier<foo,3>::value, u8"Quux") == 0);
     assert(std::strcmp(enumerator_identifier<foo,4>::value, u8"eπ") == 0);
     assert(std::strcmp(enumerator_identifier<foo,5>::value, u8"f\u03C0") == 0);

     static_assert(enumerator_value<foo,0>::value == Bar);
     static_assert(enumerator_value<foo,1>::value == Baz);
     static_assert(enumerator_value<foo,2>::value == Qux);
     static_assert(enumerator_value<foo,3>::value == Quux);
     static_assert(enumerator_value<foo,4>::value == eπ);
     static_assert(enumerator_value<foo,5>::value == f\u03C0);
          
     // universal character names handled correctly:
     assert(std::strcmp(enumerator_identifier<foo,4>::value, u8"e\u03C0") == 0);
     assert(std::strcmp(enumerator_identifier<foo,5>::value, u8"fπ") == 0);
     static_assert(enumerator_value<foo,4>::value == e\u03C0);
     static_assert(enumerator_value<foo,5>::value == fπ);

     // constant lvalue-to-rvalue conversion on array elements ok:
     constexpr const char* str = enumerator_identifier<foo,0>::value;
     static_assert(str[0] == 'b');
     static_assert(str[1] == 'a');
     static_assert(str[2] == 'r');
     static_assert(str[3] == '\0');
     
     -- end example]

## Design Log

The proposal in its current form is the result of a merge of several separate proposals.

The first was to add a core language feature that, given an enumeration type `enum E {a, b, c}`, a construct of the form `E...` would expand to a pack of the enumerator list of `E`, that being `a, b, c`.  This could be used in the usual contexts, `braced-init-list` contexts or as template or function arguments.  This was later improved by suggesting that instead a non-type parameter pack of type `E...` would match an argument of type `E`, and instead of being ill-formed, would expand to the enumerator list of `E`.  As such a pack can be formed using the proposed primitives, and as the proposed functions are more appropriate encapsulated as a library feature, it was decided that this proposal was superior as a small library addition rather than a core language change.

The second was to add a predefined template variable, originally called `__enumerator__` in the spirit of `__func__`, but we'll call it `std::enumerator_value_to_identifer` for sake of discussion, that would return the identifier string of an enumerator based on its value.  First we stress that such a facility is trivially definable using a combination of the proposed queries.  There are several reasons it was not proposed for standardization in this proposal.  Consider the following enumeration types:

    enum E1 { a, b, c };  // simple 0,1,2...n-1
    enum E2 { a = 42, b = 42, c = 43 }; // ambiguous values
    enum E3 { a = 42, b = 420000 }; // sparse values
    enum E4 { a = 1 << 0, b = 1 << 1, c = 1 << 2 }; // bit sets
    enum E5 { a = 1 << 0, b = 1 << 1, c = 1 << 2, m = 0b111 }; // masks
    
There is no single best approach that can be mandated.  What shall `std::enumerator_value_to_identifier(x)` return when x is ambiguous?  Shall it return the identifier of the first enumerator to have the value?  In what order?  Shall it return a delimited string concatenated with all the identifiers of equal value?  Again, in what order?  And how shall they be delimited? Shall it return an array or `std::set` of those of equal value instead?  Shall it fail at compile-time with an ambiguity?  Shall it have an interface like `std::multimap`?  What underlying data structure or algorithm should it use to do the lookup?  Should the case of an enumeration with contiguous enumerator values that start from zero be dealt with seperately from ones with sparse values?  What about enumerations that are used as bitsets?  What about enumerations without ambiguous enumerators at all?

All the many alternative ways of answering these questions can all be built up from the proposed queries, as they provide the complete compile-time information about the enumerator list.  We note that acceptance of this proposal would not preclude future standardization of an additional facility such as `std::enumerator_value_to_identifier` if sufficiently general answers to these questions are later found.  As a first step we decided to move standardization of `std::enumerator_value_to_identifier` to a future proposal, so as not to unnecessarily delay standardization of the more general foundation primitives.

The next proposal that was considered was creating a set of higher-level reflection facilities above the proposed primitives (and leave the primitives as an implementation detail) that would be fully integrated with other standard library facilities.  It was quickly realized that, as per `std::enumerator_value_to_identifier`, there are many different use cases and different application domains and tradeoffs.  So we decided to defer such higher-level facilities to a future proposal so as not to delay the urgently needed proposed queries.  We added the design goal for this proposal that the primitives should provide complete information, but should be minimal outside of that.

We also realized that the declaration order of enumerators may be significant for some applications and so added this information for completeness to our interface.  All other orderings can be sorted from declaration order, but once declaration order is lost it cannot be recovered.

The next key design decision was identifier representation.  As per [lex] an identifier is formed during translation phase 1-3 by mapping the source files in source encoding in an implementation-defined manner to ISO 10646 (Unicode) characters with the constraints given in [charname.allowed] and [charname.disallowed].  Characters outside the basic source character set (as with all source characters) logically encoded into univeral-character-name escape sequences.  For the remainder of translation identifiers remain in this form.  String literals have any universal-character-name escape sequences decoded during translation phase 5.  Depending on the string literal prefix a string literal is then encoded into one of five character encodings.  One of these is the implementation-defined execution character encoding, three are the standard Unicode character encodings UTF-8, UTF-16 and UTF-32, and the last is a direct encoding which is effectively equivalent to UTF-32.

It was proposed to provide an interface that took as a template parameter which of the five character encodings were desired.  For minimality it was decided that such a facility should be defered for higher-level facilities and a single encoding would be provided, given that an encoded string in a constexpr array or string literal can be transcoded with metaprogramming during translation to any other encoding anyway - so completeness remained intact.  Originally the single encoding that was considered was the implementation-defined execution encoding, but it was later realized that not all execution encodings can handle all characters (for example ASCII or Latin1), so this would violate the completeness requirement.  So it was decided to choose one of the Unicode encodings.  Implementations are already required to handle all of these, and all of them can encode all characters.  UTF-8 was selected because as an 8-bit encoding it is endianess-agnostic, unlike UTF-16 and UTF-32, and it is the most common execution encoding anyway.

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
       
But it was decided that certain uses of such an array of pointers would cause them to require static storage, and as such they would be subject to relocation costs at load-time.  For performance we did not want to unnecessarily mandate such costs.

What we really wanted was a way to expose pure compile-time accessors to the internal compiler data structure that holds the enumerator list, without providing a set data structure or algorithm - leaving this up to the library author, and for a later proposal for higher-level facilities.

To avoid the array relocation costs it was then considered to use functions:

        constexpr size_t enumerator_list_size();
        constexpr const char* enumerator_identifier(size_t index);
        constexpr E enumerator_value(size_t index);

The functions could then be backed by intrinsics, but for the later two if the index was out-of-bounds for certain uses would mandate either run-time bounds checking and error handling, or undefined behaviour.

So to avoid that we finally decided to make them Type Query Properties of existing form and the final interface was arrived at:

        namespace std
        {
        	// number of enumerators in E
        	template<class E>
        	struct enumerator_list_size : integral_constant<size_t, /* ... */> {};
        	
        	// identifier of I'th enumerator in E
        	template<class E, size_t I>
        	struct enumerator_identifier { constexpr char value[] = /* ... */; };

        	// value of I'th enumerator in E
        	template<class E, size_t I>
        	struct enumerator_value : integral_constant<E, /* ... */> {};
        };

By making the input template parameters we can allow implementations to implement them as instrinsics that access and return information directly from the internal compiler enumerator list during translation, as per other type property queries.  We added requirements that E be an enumeration type and I must be in-bounds.

Alternative interfaces exposing the same functionality would be possible, for example utilising the new template variable form coming in the C++14 standard:

     template<class E, size_t I> constexpr E enumerator_value;

But we considered keeping the API consistent with the existing style of <type_traits> more important than the (slightly) shorter access syntax. The same reasoning speaks against the longer template function syntax:

     template<class E, size_t I> constexpr E enumerator_value();


## Reference Implementation

Here is an example library interface definition for the three property queries based on the reference implementation:

The `static_asserts` are shown just for exposition, the checks themselves can take place inside the intrinsics at instantiation-time:

    template<typename E>
    struct enumerator_list_size : std::integral_constant<size_t, __enumerator_list_size(E)>
    {
        // static_assert(std::is_enum<E>::value, "E not enum type");
    };

    template<typename E, std::size_t I>
    struct enumerator_identifier
    {
        // static_assert(std::is_enum<E>::value, "E not enum type");
        // static_assert(0 <= I && I < std::enumerator_list_size<E>::value, "I out-of-bounds");

        static constexpr decltype(auto) value = __enumerator_identifier(E, I);
    };

    template<typename E, std::size_t I>
    struct enumerator_value : std::integral_constant<E, __enumerator_value(E, I)>
    {
        // static_assert(std::is_enum<E>::value, "E not enum type");
		// static_assert(0 <= I && I < std::enumerator_list_size<E>::value, "I out-of-bounds");
    };

As can be seen these are only thin wrappers around compiler intrinsics (that for example in Clang directly look up simple clang AST EnumDecl node properties).  The intrinsics only accept compile-time constants and do not generate any runtime code.

## Use Cases

An incomplete list of use cases for the three properties follows.  All uses listed can be generated during translation with metaprogramming, and can be used during translation or at run-time.  This can be shown to be true as the properties provide the complete semantic information available from the source syntax of _enumerator-list_.

Given an enumeration type E, write a generic library facility that will:

- Find the minimum and maximum enumerator (either of an enumerator, or the range from the closure of bit operations).
- Iterate over the enumerator identifiers.
- Iterate over the enumerator values.
- Count the number of enumerators.
- Count the number of distinct enumerator values.
- Count the number of enumerators with a specific value.
- `static_assert` that the enumerators are declared in alphabetical order.
- `static_assert` that the enumerators are declared in an order dependant on their name.
- `static_assert` that the enumerators are declared in an order dependant on their value.
- `static_assert` that the enumerator identifiers match a certain naming convention.
- `static_assert` that the relationship between the enumerator identifiers and their values fit a constaint.
- `static_assert` any constaint on the relationship between enumerator name, value and declared order.
- Sort the enumerators identifiers/values in any order.
- Lookup the set of enumerators identifiers with a given enumerator value, returned in any encoding or form.
- Lookup the value of an enumerator given a string of its identifier in any encoding.
- Determine the relationship between enumerator values (sparse, dense) and create an efficient jump table or associative data structure.
- Create a jump table or associative data structure based on enumerator identifier (any encoding), or some function of the identifier text.

## Example Usage

As for the existing properties `std::rank` and `std::extent`, the individual properties can be expanded into a pack or an array with an index sequence pack (`std::make_index_sequence`, see N3658).  For example:

	template<class E, class IdxSeq>
	struct enumerator_data_t;

	template<class E, size_t... Idx>
	struct enumerator_data_t<E, std::index_sequence<Idx...>> {
		static constexpr size_t count = std::enumerator_list_size<E>::value;
		static constexpr E values[] = { std::enumerator_value<E, Idx>::value... };
		static constexpr char const *names[] = { std::enumerator_identifier<E, Idx>::value... };
	};

	template<class E>
	using enumerator_data_t = enumerator_data_t<E, std::make_index_sequence< std::enumerator_list_size<E>::value >>;

	template<typename E, size_t... Idx> 
	constexpr E enumerator_data_t<E, std::index_sequence<Idx...>>::values[];
	template<typename E, size_t... Idx> 
	constexpr char const * enumerator_data_t<E, std::index_sequence<Idx...>>::names[];

	// simple usage: list all enumerator in their order of definition
	enum class E1 { first = 99, second = first, third };
	using E1D = enumerator_data_t<E1>;
	for (int i=0; i<E1D::count; i++)
		std::cout << E1D::names[i] << " = " << (int)E1D::values[i] << std::endl;

This builds an intermediate-level interface comparable to e.g. Java's Class.getEnumConstants().  From here constexpr functions can be written to operate on the enumerator data:

	// determines the largest numerical value that is defined by the enum
	template<typename E>
	constexpr E enum_max_value() {
		using ED = enumerator_data_t<E>;
		using UT = std::underlying_type_t<E>;
		static_assert(ED::count>0, "maximum not defined on empty enum");
		E ret = ED::values[0];
		for (size_t i=1, e=ED::count; i<e; ++i)
			if (static_cast<UT>(ret)<static_cast<UT>(ED::values[i]))
				ret = ED::values[i];
		return ret;
	}

Having the defined value range of an enumeration at hand allows creating wrappers around std::bitset or std::array taking the enum type as the key. These could be more efficient for certain applications, constexpr enabled replacements for std::set/map for certain tasks.

Certain traits regarding the enum can then be determined quite easily with a similar algorithms:

	// determines if the enumerators of E follow the default valuing
	// if yes, then calculating the enumerator index from an value of E is trivial
	template<typename E>
	constexpr bool is_trivially_valued_enum() {
		using ED = enumerator_data_t<E>;
		using UT = std::underlying_type_t<E>;
		for (size_t i=0, e=ED::count; i<e; ++i)
			if (static_cast<UT>(ret) != static_cast<UT>(i))
				return false;
		return true;
	}

... which could be used to check correct usage of a very simple value-to-identifier conversion function:

	template<typename E>
	constexpr const char *enum_value_to_str(E val) {
		static_assert(is_trivially_valued_enum<E>(), "only implemented for simple enums");
		size_t idx = static_cast<size_t>(val);
		if (idx >= std::enumerator_list_size<E>::value)
			throw std::out_of_range("invalid enum value");
		return enumerator_data_t<E>::names[idx];
	}

Of course, more universally applyable lookup algorithms can also be implemented. One option would be simply using a std::map or std::unordered_map for lookup, another to perform a binary search on a sorted array. Creating a lookup table for enumerations with a small value range should deliver performance comparable to compiler generated switch statements. An automatic selection of the most appropriate algorithm for a given enum type could also be implemented given the right support traits.

Having good lookup method(s) in place would enable treating any enum as an ordinal type. The bitset/array wrappers mentioned above could apply this transformation instead of using the enum value directly to get a (for any given enum type) gapless index range.

Performing a reverse lookup from an identifier string to the associated value is of course also possible. For this task, specific requirements will probably vary widely between applications (case (in)sensitive comparision, adding/removing pre-/post-fixes, fuzzy search etc.)  But all of these are implementable given the proposed interface.

While some of the advanced functionality mentioned in this section might be of general enough use to potentially warrant standardization, the specifics of such APIs will take longer to establish existing practice, and so should not delay initial adoption of the general underlying interface proposed here.

## Acknowledgements / References

We would like to thank David Krauss and Thiago Macieira for valuable initial feedback on this proposal.

A reference implementation of the proposed property queries is part of a clang branch (containing additional intrinsics for other reflection tasks) that can be checked out from github: https://github.com/ChristianKaeser/clang-reflection
