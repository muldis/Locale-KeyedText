use 5.008001;
use utf8;
use strict;
use warnings;

###########################################################################
###########################################################################

# Constant values used by packages in this file:
my $EMPTY_STR = q{};

###########################################################################
###########################################################################

{ package Locale::KeyedText; # package
    BEGIN {
        our $VERSION = '2.000000';
        $VERSION = eval $VERSION;
    }
} # package Locale::KeyedText

###########################################################################
###########################################################################

{ package Locale::KeyedText::Message; # class
    BEGIN {
        our $VERSION = '2.000000';
        $VERSION = eval $VERSION;
    }

    # has _msg_key
        # isa Str
        # default ''
        # The machine-readable key that uniquely ident this message.
    sub _msg_key {
        my $self = shift;
        $self->{_msg_key} = $_[0] if scalar @_;
        return $self->{_msg_key};
    }

    # has _msg_vars
        # isa HashRef
            # One elem per var:
                # hkey is Str - var name
                # hval is Any - current value for var
        # default {}
        # Named variables for messages, if any, go here.
    sub _msg_vars {
        my $self = shift;
        $self->{_msg_vars} = $_[0] if scalar @_;
        return $self->{_msg_vars};
    }

###########################################################################

sub new {
    my ($class, @args) = @_;
    $class = (blessed $class) || $class;

    my $params = $class->BUILDARGS( @args );

    my $self = bless {}, $class;

    # Set attribute default values.
    $self->_msg_key( '' );
    $self->_msg_vars( {} );

    $self->BUILD( $params );

    return $self;
}

###########################################################################

sub BUILDARGS {
    my ($class, @args) = @_;
    if (@args == 1 and ref $args[0] eq 'HASH') {
        # Constructor was called with (possibly zero) named arguments.
        return { %{$args[0]} };
    }
    elsif ((scalar @args % 2) == 0) {
        # Constructor was called with (possibly zero) named arguments.
        return { @args };
    }
    else {
        # Constructor was called with odd number positional arguments.
        $class->_die_with_msg( 'LKT_ARGS_BAD_PSEUDO_NAMED' );
    }
}

###########################################################################

sub BUILD {
    my ($self, $args) = @_;
    my ($msg_key, $msg_vars_ref) = @{$args}{'msg_key', 'msg_vars'};

    if (!defined $msg_vars_ref) {
        $msg_vars_ref = {};
    }

    $self->_assert_arg_str( 'new', ':$msg_key!', $msg_key );
    $self->_assert_arg_hash( 'new', ':%msg_vars?', $msg_vars_ref );

    $self->_msg_key( $msg_key );
    $self->_msg_vars( {%{$msg_vars_ref}} );

    return;
}

###########################################################################

sub export_as_hash {
    my ($self) = @_;
    return {
        'msg_key'  => $self->_msg_key(),
        'msg_vars' => {%{$self->_msg_vars()}},
    };
}

###########################################################################

sub get_msg_key {
    my ($self) = @_;
    return $self->_msg_key();
}

sub get_msg_var {
    my ($self, $var_name) = @_;
    $self->_assert_arg_str( 'get_msg_var', '$var_name!', $var_name );
    return $self->_msg_vars()->{$var_name};
}

sub get_msg_vars {
    my ($self) = @_;
    return {%{$self->_msg_vars()}};
}

######################################################################

sub as_debug_string {
    my ($self) = @_;
    my $msg_key = $self->_msg_key();
    my $msg_vars = $self->_msg_vars();
    return '  Debug String of a Locale::KeyedText::Message object:'
         . "\n"
         . '    $msg_key: "' . $msg_key . '"'
         . "\n"
         . '    %msg_vars: {' . (join q{, }, map {
               '"' . $_ . '"="' . (defined $msg_vars->{$_}
                   ? $msg_vars->{$_} : $EMPTY_STR) . '"'
           } sort keys %{$msg_vars}) . '}'
         . "\n";
}

###########################################################################

sub _die_with_msg {
    my ($self, $msg_key, $msg_vars_ref) = @_;
    $msg_vars_ref ||= {};
    $msg_vars_ref->{'CLASS'} = 'Locale::KeyedText::Message';
    die Locale::KeyedText::Message->new({
        'msg_key' => $msg_key, 'msg_vars' => $msg_vars_ref });
}

sub _assert_arg_str {
    my ($self, $meth, $arg, $val) = @_;
    $self->_die_with_msg( 'LKT_ARG_UNDEF',
            { 'METH' => $meth, 'ARG' => $arg } )
        if !defined $val;
    $self->_die_with_msg( 'LKT_ARG_EMP_STR',
            { 'METH' => $meth, 'ARG' => $arg } )
        if $val eq $EMPTY_STR;
}

sub _assert_arg_hash {
    my ($self, $meth, $arg, $val) = @_;
    $self->_die_with_msg( 'LKT_ARG_UNDEF',
            { 'METH' => $meth, 'ARG' => $arg } )
        if !defined $val;
    $self->_die_with_msg( 'LKT_ARG_NO_HASH',
            { 'METH' => $meth, 'ARG' => $arg, 'VAL' => $val } )
        if ref $val ne 'HASH';
    $self->_die_with_msg( 'LKT_ARG_HASH_KEY_EMP_STR',
            { 'METH' => $meth, 'ARG' => $arg } )
        if exists $val->{$EMPTY_STR};
}

###########################################################################

} # class Locale::KeyedText::Message

###########################################################################
###########################################################################

{ package Locale::KeyedText::Translator; # class
    BEGIN {
        our $VERSION = '2.000000';
        $VERSION = eval $VERSION;
    }

    use Scalar::Util 'blessed';

    # has _set_names
        # isa ArrayRef
            # One elem per set name:
                # elem is Str
        # default []
        # List of Template module Set Names to search.
    sub _set_names {
        my $self = shift;
        $self->{_set_names} = $_[0] if scalar @_;
        return $self->{_set_names};
    }

    # has _member_names
        # isa ArrayRef
            # One elem per member name:
                # elem is Str
        # default []
        # List of Template module Member Names to search.
    sub _member_names {
        my $self = shift;
        $self->{_member_names} = $_[0] if scalar @_;
        return $self->{_member_names};
    }

###########################################################################

sub new {
    my ($class, @args) = @_;
    $class = (blessed $class) || $class;

    my $params = $class->BUILDARGS( @args );

    my $self = bless {}, $class;

    # Set attribute default values.
    $self->_set_names( [] );
    $self->_member_names( [] );

    $self->BUILD( $params );

    return $self;
}

###########################################################################

sub BUILDARGS {
    my ($class, @args) = @_;
    if (@args == 1 and ref $args[0] eq 'HASH') {
        # Constructor was called with (possibly zero) named arguments.
        return { %{$args[0]} };
    }
    elsif ((scalar @args % 2) == 0) {
        # Constructor was called with (possibly zero) named arguments.
        return { @args };
    }
    else {
        # Constructor was called with odd number positional arguments.
        $class->_die_with_msg( 'LKT_ARGS_BAD_PSEUDO_NAMED' );
    }
}

###########################################################################

sub BUILD {
    my ($self, $args) = @_;
    my ($set_names_ref, $member_names_ref)
        = @{$args}{'set_names', 'member_names'};

    $self->_assert_arg_ary( 'new', ':@set_names!', $set_names_ref );
    $self->_assert_arg_ary( 'new', ':@member_names!', $member_names_ref );

    $self->_set_names( [@{$set_names_ref}] );
    $self->_member_names( [@{$member_names_ref}] );

    return;
}

###########################################################################

sub export_as_hash {
    my ($self) = @_;
    return {
        'set_names'    => [@{$self->_set_names()}],
        'member_names' => [@{$self->_member_names()}],
    };
}

###########################################################################

sub get_set_names {
    my ($self) = @_;
    return [@{$self->_set_names()}];
}

sub get_member_names {
    my ($self) = @_;
    return [@{$self->_member_names()}];
}

######################################################################

sub as_debug_string {
    my ($self) = @_;
    my $set_names = $self->_set_names();
    my $member_names = $self->_member_names();
    return '  Debug String of a Locale::KeyedText::Translator object:'
         . "\n"
         . '    @set_names: ["' . (join q{", "}, @{$set_names}) . '"]'
         . "\n"
         . '    @member_names: ["'
             . (join q{", "}, @{$member_names}) . '"]'
         . "\n";
}

###########################################################################

sub get_set_member_combinations {
    my ($self) = @_;
    my @combinations = ();
    for my $member_name (@{$self->_member_names()}) {
        for my $set_name (@{$self->_set_names()}) {
            push @combinations, $set_name . $member_name;
        }
    }
    return \@combinations;
}

###########################################################################

sub translate_message {
    my ($self, $message) = @_;

    $self->_assert_arg_msg( 'translate_message', '$message!', $message );

    my $text = undef;
    SET_MEMBER:
    for my $module_name (@{$self->get_set_member_combinations()}) {
        # Determine if requested template module is already loaded.
        # It may have been embedded in a core program file and hence
        # should never be loaded by translate_message().
        my $module_is_loaded
            = $self->template_module_is_loaded( $module_name );

        # Try to load an external Perl template module; on a require
        # failure, we assume that module intentionally doesn't exist,
        # and so skip to the next candidate module name.
        if (!$module_is_loaded) {
            eval {
                $self->load_template_module( $module_name );
            };
            next SET_MEMBER
                if $@;
        }

        # Try to fetch template text for the given message key from the
        # successfully loaded template module; on a function call
        # death, assume module is damaged and say so; an undefined
        # ret val means module doesn't define key, skip to next module.
        $text = $self->get_template_text_from_loaded_module( $module_name,
            $message->get_msg_key() ); # let escape any thrown exception
        next SET_MEMBER
            if !defined $text;

        # We successfully got template text for the message key, so
        # interpolate the message vars into it and return that.
        $text = $self->interpolate_vars_into_template_text(
            $text, $message->get_msg_vars() );
        last SET_MEMBER;
    }

    return $text;
}

###########################################################################

sub template_module_is_loaded {
    my ($self, $module_name) = @_;
    $self->_assert_arg_str( 'template_module_is_loaded',
        '$module_name!', $module_name );
    no strict 'refs';
    no warnings 'deprecated';  # TODO - Use a better test on next line.
    return defined %{$module_name . '::'};
}

sub load_template_module {
    my ($self, $module_name) = @_;

    $self->_assert_arg_str( 'load_template_module',
        '$module_name!', $module_name );

    # Note: We have to invoke this 'require' in an eval string
    # because we need the bareword semantics, where 'require'
    # will munge the package name into file system paths.
    eval "require $module_name;";
    $self->_die_with_msg( 'LKT_T_FAIL_LOAD_TMPL_MOD',
            { 'METH' => 'load_template_module',
            'TMPL_MOD_NAME' => $module_name, 'REASON' => $@ } )
        if $@;

    return;
}

sub get_template_text_from_loaded_module {
    my ($self, $module_name, $msg_key) = @_;

    $self->_assert_arg_str( 'get_template_text_from_loaded_module',
        '$module_name!', $module_name );
    $self->_assert_arg_str( 'get_template_text_from_loaded_module',
        '$msg_key!', $msg_key );

    my $text = undef;
    eval {
        $text = $module_name->get_text_by_key( $msg_key );
    };
    $self->_die_with_msg( 'LKT_T_FAIL_GET_TMPL_TEXT',
            { 'METH' => 'get_template_text_from_loaded_module',
            'TMPL_MOD_NAME' => $module_name, 'REASON' => $@ } )
        if $@;

    return $text;
}

sub interpolate_vars_into_template_text {
    my ($self, $text, $msg_vars_ref) = @_;

    $self->_die_with_msg( 'LKT_ARG_UNDEF',
            { 'METH' => 'interpolate_vars_into_template_text',
            'ARG' => '$text!' } )
        if !defined $text;
    $self->_assert_arg_hash( 'interpolate_vars_into_template_text',
        '%msg_vars!', $msg_vars_ref );

    while (my ($var_name, $var_value) = each %{$msg_vars_ref}) {
        my $var_value_as_str
            = defined $var_value ? "$var_value"
            :                      $EMPTY_STR
            ;
        $text =~ s/ \< $var_name \> /$var_value_as_str/xg;
    }

    return $text;
}

###########################################################################

sub _die_with_msg {
    my ($self, $msg_key, $msg_vars_ref) = @_;
    $msg_vars_ref ||= {};
    $msg_vars_ref->{'CLASS'} = 'Locale::KeyedText::Translator';
    die Locale::KeyedText::Message->new({
        'msg_key' => $msg_key, 'msg_vars' => $msg_vars_ref });
}

sub _assert_arg_str {
    my ($self, $meth, $arg, $val) = @_;
    $self->_die_with_msg( 'LKT_ARG_UNDEF',
            { 'METH' => $meth, 'ARG' => $arg } )
        if !defined $val;
    $self->_die_with_msg( 'LKT_ARG_EMP_STR',
            { 'METH' => $meth, 'ARG' => $arg } )
        if $val eq $EMPTY_STR;
}

sub _assert_arg_ary {
    my ($self, $meth, $arg, $val) = @_;
    $self->_die_with_msg( 'LKT_ARG_UNDEF',
            { 'METH' => $meth, 'ARG' => $arg } )
        if !defined $val;
    $self->_die_with_msg( 'LKT_ARG_NO_ARY',
            { 'METH' => $meth, 'ARG' => $arg, 'VAL' => $val } )
        if ref $val ne 'ARRAY';
    $self->_die_with_msg( 'LKT_ARG_ARY_NO_ELEMS',
            { 'METH' => $meth, 'ARG' => $arg } )
        if @{$val} == 0;
    for my $val_elem (@{$val}) {
        $self->_die_with_msg( 'LKT_ARG_ARY_ELEM_UNDEF',
                { 'METH' => $meth, 'ARG' => $arg } )
            if !defined $val_elem;
        $self->_die_with_msg( 'LKT_ARG_ARY_ELEM_EMP_STR',
                { 'METH' => $meth, 'ARG' => $arg } )
            if $val_elem eq $EMPTY_STR;
    }
}

sub _assert_arg_hash {
    my ($self, $meth, $arg, $val) = @_;
    $self->_die_with_msg( 'LKT_ARG_UNDEF',
            { 'METH' => $meth, 'ARG' => $arg } )
        if !defined $val;
    $self->_die_with_msg( 'LKT_ARG_NO_HASH',
            { 'METH' => $meth, 'ARG' => $arg, 'VAL' => $val } )
        if ref $val ne 'HASH';
    $self->_die_with_msg( 'LKT_ARG_HASH_KEY_EMP_STR',
            { 'METH' => $meth, 'ARG' => $arg } )
        if exists $val->{$EMPTY_STR};
}

sub _assert_arg_msg {
    my ($self, $meth, $arg, $val) = @_;
    $self->_die_with_msg( 'LKT_ARG_UNDEF',
            { 'METH' => $meth, 'ARG' => $arg } )
        if !defined $val;
    $self->_die_with_msg( 'LKT_ARG_NO_EXP_TYPE', { 'METH' => $meth,
            'ARG' => $arg, 'EXP_TYPE' => 'Locale::KeyedText::Message',
            'VAL' => $val } )
        if !blessed $val or !$val->isa( 'Locale::KeyedText::Message' );
}

###########################################################################

} # class Locale::KeyedText::Translator

###########################################################################
###########################################################################

1;
__END__

=pod

=encoding utf8

=head1 NAME

Locale::KeyedText -
Refer to user messages in programs by keys

=head1 VERSION

This document describes Locale::KeyedText version 2.0.0.

It also describes the same-number versions of Locale::KeyedText::Message
("Message") and Locale::KeyedText::Translator ("Translator").

I<Note that the "Locale::KeyedText" package serves only as the name-sake
representative for this whole file, which can be referenced as a unit by
documentation or 'use' statements or Perl archive indexes.  Aside from
'use' statements, you should never refer directly to "Locale::KeyedText" in
your code; instead refer to other above-named packages in this file.>

=head1 SYNOPSIS

    use Locale::KeyedText;

    main();

    sub main {
        # Create a translator.
        my $translator = Locale::KeyedText::Translator->new({
            'set_names' => ['MyLib::Lang::', 'MyApp::Lang::'],
                # set package prefixes for localized app components
            'member_names' => ['Eng', 'Fr', 'De', 'Esp'],
                # set list of available languages in order of preference
        });

        # This will print 'Enter 2 Numbers' in the first of the four
        # languages that has a matching template available.
        print $translator->translate_message(
            Locale::KeyedText::Message->new({
                'msg_key' => 'MYAPP_PROMPT' }) );

        # Read two numbers from the user.
        my ($first, $second) = <STDIN>;

        # Print a statement giving the operands and their sum.
        MyLib->add_two( $first, $second, $translator );
    }

    package MyLib; # module

    sub add_two {
        my (undef, $first, $second, $translator) = @_;
        my $sum = $first + $second;

        # This will print '<FIRST> plus <SECOND> equals <RESULT>' in
        # the first possible language.  For example, if the user
        # inputs '3' and '4', it the output will be '3 plus 4 equals 7'.
        print $translator->translate_message(
            Locale::KeyedText::Message->new({ 'msg_key' => 'MYLIB_RESULT',
                'msg_vars' => { 'FIRST' => $first, 'SECOND' => $second,
                'RESULT' => $sum } }) );
    }

=head1 DESCRIPTION

=head2 Introduction

Many times during a program's operation, the program (or a package it uses)
will need to display a message to the user, or generate a message to be
shown to the user.  Sometimes this is an error message of some kind, but it
could also be a prompt or response message for interactive systems.

If the program or any of its components are intended for widespread use
then it needs to account for a variance of needs between its different
users, such as their preferred language of communication, or their
privileges regarding access to information details, or their technical
skills.  For example, a native French or Chinese speaker often prefers to
communicate in those languages.  Or, when viewing an error message, the
application's developer should see more details than joe public would.

Alternately, sometimes a program will raise a condition or error that,
while resembling a message that would be shown to a user, is in fact meant
to be interpreted by the machine itself and not any human user.  In some
situations, a shared program component may raise such a condition, and one
application may handle it internally, while another one displays it to the
user instead.

Locale::KeyedText provides a simple but effective mechanism for
applications and packages that empowers single binaries to support N
locales or user types simultaneously, and that allows any end users to add
support for new languages easily and without a recompile (such as by simply
copying files), often even while the program is executing.

Locale::KeyedText gives your application the maximum amount of control as
to what the user sees; it never outputs anything by itself to the user, but
rather returns its results for calling code to output as it sees fit.  It
also does not make direct use of environment variables, which can aid in
portability.

Locale::KeyedText itself is trivially easy to install, since it is written
in pure Perl and it has no non-Core dependencies.

Practically speaking, Locale::KeyedText doesn't actually do a lot
internally; it exists mainly to document a certain localization methodology
in an easily accessable manner, such that would not be possible if its
functionality was subsumed into a larger package that would otherwise use
it.  Hereafter, if any other package or application says that it uses
Locale::KeyedText, that is a terse way of saying that it subscribes to the
localization methodology that is described here, and hence provides these
benefits to developers and users alike.

For some practical examples of Locale::KeyedText in use, see the /examples
directory of this distribution.

=head2 How It Works

Modern programs or database systems often refer to an error condition by an
internal code which is guaranteed to be unique for a situation, and this is
mapped to a user-readable message at some point.  For example, Oracle
databases often have error codes in a format like 'ORA-03542'.  These codes
are "machine readable"; any application receiving such a code can identify
it easily in its conditional logic, using a simple 'equals', and then the
application can "do the right thing".  No parsing or ambiguity involved.
By contrast, if a program simply returned words for the user, such as
'error opening file', programs would have a harder time figuring out the
best way to deal with it.  But for displaying to users, easy messages are
better.

I have found that when it comes to getting the most accurate program text
for users, we still get the best results by having a human being write out
that text themselves.

What Locale::KeyedText does is associate each member in a set of key-codes,
which are hard-coded into your application or package, with one or more
text strings to show human users.  This association would normally be
stored in a Perl file that defines and returns an anonymous hash
definition.  While it is obvious that people who would be writing the text
would have to know how to edit Perl files, this shouldn't be a problem
because Locale::KeyedText is only meant to be used with user text that is
associated with hard-coded program conditions.  In other words, this user
text is *part of the program*, and not the program's users' own data; only
someone already involved in making the program would be editing them.  At
the same time, this information is in separate resource files used by the
program, so that if you wanted to upgrade or localize what text the user
sees, you only have to update said separate resource files, and not change
your main program.

I<Note that an update is planned for Locale::KeyedText that will enable
user text to be stored in non-Perl external files, such as a 2-column
plain-text format that will be much easier for a non-programmer to edit.
But the current Perl-based solution will also be kept due to its more
dynamic capabilities.>

I was inspired to have this organization partly by how Mac OS X manages its
resources.  It is the standard practice for Mac OS X programs, including
the operating system itself, to have the user language data in separate
files (usually XML files I think) from the main program binary.  Each user
language is in a separate file, and adding a localization to a Mac OS X
program is as simple as adding a language file to the program package.  No
recompilation necessary.  This is something that end users could do,
although program package installers usually do it.  An os-level preference
/ control-panel displays a list of all the languages your programs do or
might have, and lets you arrange the list in order of preference.  When you
open a program, it will search for language files specific to the program
in the order you chose so to pick a supported language closest to your
preference.  Presumably the messages in these files are looked up by the
program using keys.  Mac OS X (and the previous non-Unix Mac OS) handles
lots of other program resources as data files as well, making them easy to
upgrade.

Locale::KeyedText aims to bring this sort of functionality to Perl packages
or programs.  Your package or program can be distributed with one or more
resource files containing text for users, and your program would use
associated keys internally.

It is strongly suggested (but not required) that each Perl package which
uses this would come up with keys which are unique across all Perl packages
(perhaps the key name can start with the package name?).  An advantage of
this is that, for example, your package could come with a set of user
messages, but another package or program which uses yours may wish to
override some of your messages, showing other messages instead which are
more appropriate to the context in which they are using your package.  One
can override simply by using the same key code with a new user message in
one of their own resource files.  At some appropriate place, usually in the
main program, Locale::KeyedText can be given input that says what resource
files it should use and in what order they should be consulted.  When
Locale::KeyedText is told to fetch the user message for a certain code, it
returns the first one it finds.  This also works for the multiple language
or permissions issue; simply order the files appropriately in the search
list.  The analogy is similar to inheriting from multiple packages which
have the same method names as you or each other, or having multiple search
directories in your path that packages could be installed in.

Generally, when a program package would return a code-key to indicate a
condition, often it will also provide some variable values to be
interpolated into the user strings; Locale::KeyedText would also handle
this.

A program generates a Message that contains all possibly useful details, so
that each Template can optionally use them; but often a template will
choose to show less than all of the available details depending on the
intended viewer.

=head2 Compared to Other Solutions

One of the main distinctions of this approach over similar packages is that
text is always looked up by a key which is not meant to be meaningful for a
user.  Whereas, with the other packages like "gettext" it looks like you
are supposed to pass in english text and they translate it, which could
produce ambiguous results or associations.  Or alternately, the other
packages require your text data to be stored in a format other than Perl
files.  Or alternately they have a compiled C component or otherwise have
non-trivial external dependencies; Locale::KeyedText has no non-trivial
external dependencies (it is very simple).

There are other differences.  Where other solutions take variables, they
seem to be positional (like with 'sprintf'); whereas, Locale::KeyedText has
named variables, which can be used in any order, or not used at all, or
used multiple times.  Locale::KeyedText is generally a simpler solution
than alternatives, and doesn't know about language specific details like
encodings or plurality.

My understanding of alternate solutions like "gettext" suggests that they
use a compile-time macro-based approach to substitute the user's preferred
language into the program code itself, so it then becomes a version of that
language.  By contrast, Locale::KeyedText does no compile time binding and
will support multiple languages or locales simultaneously at run time.

=head1 INTERFACE

The interface of Locale::KeyedText is entirely object-oriented; you use it
by creating objects from its member classes, usually invoking C<new()> on
the appropriate class name, and then invoking methods on those objects.
All of their attributes are private, so you must use accessor methods.
Locale::KeyedText does not declare any subroutines or export such.

The usual way that Locale::KeyedText indicates a failure is to throw an
exception; most often this is due to invalid input.  If an invoked routine
simply returns, you can assume that it has succeeded, even if the return
value is undefined.

=head2 The Locale::KeyedText::Message Class

A Message object is a simple container which stores data to be used or
displayed by your program.  The Message class is pure and deterministic,
such that all of its class and object methods will each return the same
result and/or make the same change to an object when the permutation of its
arguments and any invocant object's attributes is identical; they do not
interact with the outside environment at all.

A Message object has two main attributes:

=over

=item C<$!msg_key> - B<Message Key>

Str - This uniquely identifies the type of message that the object
represents (or gives the name of a condition being reported, if it is used
as an exception payload).  The key is intended to be read by a machine and
mapped to a user-readable message; the key itself is not meant to be
meaningful to a user.  The Message Key can be any defined and non-empty
string.

=item C<%!msg_vars> - B<Message Variables>

Hash(Str) of Any - This contains zero or more variable names and values
that are associated with the message, and can be interpolated into the
human-readable version.  Each variable name is a machine-readable short
string; the allowed variable names you can have depend on the Message Key
it is being used with (others are ignored).  Each variable name can be any
defined and non-empty string, and each variable value can be anything at
all.  Note that while the Hash itself is copied on input and output, any
variable values which are references will be passed by reference, so you
may store references to other objects in them if you wish.

=back

This is the main Message constructor method:

=over

=item C<new( :$msg_key!, :%msg_vars? )>

This method creates and returns a new Locale::KeyedText::Message object.
The Message Key attribute of the new object is set from the named parameter
$msg_key (a string); the optional named parameter %msg_vars (a hash ref)
sets the "Message Variables" attribute if the corresponding argument is
provided (it defaults to empty if the argument is not provided).

Some example usage:

    my $message = Locale::KeyedText::Message->new({
        'msg_key' => 'FOO_GOT_NO_ARGS' });
    my $message2 = Locale::KeyedText::Message->new({
        'msg_key' => 'TABLE_COL_NO_EXIST',
        'msg_vars' => {
            'GIVEN_TABLE_NAME' => $table_name,
            'GIVEN_COL_NAME' => $col_name,
        } });

Note that a Message object does not permit changes to its attributes; they
must all be set when the object is constructed.  If you want to
conceptually change an existing Message object, you must create a new
object that is a clone of the first but for the changes.

=back

A Message object has these methods:

=over

=item C<export_as_hash()>

This method returns a deep copy of this Message as a Hash ref of 2
elements, which correspond to the 2 named parameters of new().

=item C<get_msg_key()>

This method returns the Message Key attribute of its object.

=item C<get_msg_var( $var_name! )>

This method returns the Message Variable value (a string) associated with
the variable name specified in the positional parameter $var_name (a
string).

=item C<get_msg_vars()>

This method returns all Message Variable names and values of this object as
a hash ref.

=item C<as_debug_string()>

This method returns a stringified version of this object which is suitable
for debugging purposes (such as to test that the object's contents look
good at a glance); no attribute values are escaped and you shouldn't try to
extract them.  This method is also defined as the implicit handler when
coercing this object to a string.

=back

=head2 The Template Modules

Locale::KeyedText doesn't define any "Template" modules, but it expects you
to make modules having a specific simple API that will serve their role.

For example, inside the text Template file "MyApp/L/Eng.pm" you can have:

    my $TEXT_STRINGS = {
        'MYAPP_HELLO' => q[Welcome to MyApp.],
        'MYAPP_GOODBYE' => q[Goodbye!],
        'MYAPP_PROMPT'
            => q[Enter a number to be inverted, or press ENTER to quit.],
        'MYAPP_RESULT' => q[The inverse of "<ORIGINAL>" is "<INVERTED>".],
    };

    { package MyApp::L::Eng; # module
        sub get_text_by_key {
            my (undef, $msg_key) = @_;
            return $TEXT_STRINGS->{$msg_key};
        }
    } # module MyApp::L::Eng

And inside the text Template file "MyApp/L/Fre.pm" you can have:

    my $TEXT_STRINGS = {
        'MYAPP_HELLO' => q[Bienvenue allé MyApp.],
        'MYAPP_GOODBYE' => q[Salut!],
        'MYAPP_PROMPT'
            => q[Fournir nombre être inverser, ou appuyer sur]
               . q[ ENTER être arrêter.],
        'MYAPP_RESULT' => q[Renversement "<ORIGINAL>" est "<INVERTED>".],
    };

    { package MyApp::L::Fre; # module
        sub get_text_by_key {
            my (undef, $msg_key) = @_;
            return $TEXT_STRINGS->{$msg_key};
        }
    } # module MyApp::L::Fre

A Template module is very simple, consisting mainly of a data-stuffed hash
and an accessor method to read values from it by key.  Each template hash
key corresponds to the Message Key attribute of a Message object, and each
hash value contains the user-readable message text associated with the
Message; this user string may also contain variable names that correspond
to Message Variables, which will be substituted at run-time before the text
is shown to the user.

Each Template module ideally comes as part of a set, at least one member
large, with each set member being an an exclusive alternative for the rest
of the set. There is a separate template module for each distinct "user
language" (or "user type") for each distinct Message; each file can be
shared by multiple Messages but the whole module must represent a single
language.

The name of each Template module has two parts, the Set Name and the Member
Name.  The Set Name comes first and makes up most of the module name; it
must be the same for every module in the same set as the current one.  The
Member Name comes next and is what distinguishes each module from others in
its set. For maximum flexibility in their use, the full name of a module
consists of the two parts concatenated without any delimiter.  This means,
for example, that the full module names in a set could be either
[Foo::L::Eng, Foo::L::Fre, Foo::L::Ger] or [L::FooEng, L::FooFre,
L::FooGer]; the latter is mainy useful if you want modules from multiple
sets in the same disk directory.  In the first example, the Set Name is
"Foo::L::" and in the second it is "L::Foo".

A library could be distributed with a Template module set that is specific
to it, another library likewise, and a program which uses both libraries
could have yet another set for itself.  When the program is run, it would
determine either from a user config file or a user interface that the
current user is fluent in (and prefers) language A but also understands
language B.  Later on, if for example the first library generates an error
message and wants it shown to the user, the main program would check each
of the 3 Template module sets in turn, looking at just the set member for
each that corresponds to language A, looking for a match to said error
message.  If it finds one, then that is displayed; if not, it then checks
each set's member for language B and displays that; and so on.

I<For the present, Locale::KeyedText expects its Template modules to come
from Perl modules, but in the future they may alternately be something
else, such as XML or tab-delimited plain text files.>

=head2 The Locale::KeyedText::Translator Class

While a Translator object stores some attributes for configuration, its
main purpose is to convert Message objects on demand into user-readable
message strings, using data from external Template modules as a template.
The Translator class as a whole is not pure and deterministic because it
invokes user-defined external files for reading, mainly in the
C<translate_message()> method, but it has no other side effects.

A Translator object has 2 main attributes:

=over

=item C<@!set_names> - B<Set Names>

Array of Str - This stores an ordered list of one or more elements where
each element is a Template module Set Name.  When we have to translate a
message, the corresponding Template modules will be searched in the order
they appear in this array until a match for that message is found.  Since a
program or library may wish to override the user text of another library
which it uses, the Template module for the program or first library should
appear first in the array.  Each Set Name can be any defined and non-empty
string.

=item C<@!member_names> - B<Member Names>

Array of Str - This stores an ordered list one or more elements where each
element is a Template module Member Name and usually corresponds to a
language like English or French.  The order of these items corresponds to
an individual user's (or user role's) preferences such that each says what
language they prefer to communicate in, and what their backup choices are,
in order, if preferred ones aren't supported by a program or its libraries.
When translating a message, a match in found in the most preferred language
is used.  Each Set Name can be any defined and non-empty string.

=back

This is the main Translator constructor method:

=over

=item C<new( :@set_names!, :@member_names! )>

This method creates and returns a new Locale::KeyedText::Translator object.
The Set Names property of the new object is set from the named parameter
@set_names (an array ref), and Member Names is set from the named parameter
@member_names (an array ref).

Some example usage:

    my $translator = Locale::KeyedText::Translator->new({
        'set_names' => ['Foo::L::','Bar::L::'],
        'member_names' => ['Eng', 'Fre', 'Ger'] });
    my $translator2 = Locale::KeyedText::Translator->new({
        'set_names' => ['Foo::L::'], 'member_names' => ['Eng'] });

Note that a Translator object does not permit changes to its attributes;
they must all be set when the object is constructed.  If you want to
conceptually change an existing Translator object, you must create a new
object that is a clone of the first but for the changes.

=back

A Translator object has these methods:

=over

=item C<export_as_hash()>

This method returns a deep copy of this Translator as a Hash ref of 2
elements, which correspond to the 2 named parameters of new().

=item C<get_set_names()>

This method returns all Set Names elements in this object as an array ref.

=item C<get_member_names()>

This method returns all Member Names elements in this object as an array
ref.

=item C<as_debug_string()>

This method returns a stringified version of this object which is suitable
for debugging purposes (such as to test that the object's contents look
good at a glance); no attribute values are escaped and you shouldn't try to
extract them.  This method is also defined as the implicit handler when
coercing this object to a string.

=item C<get_set_member_combinations()>

This method returns an array ref having all combinations of this object's
Set Names and Member Names elements, concatenated in the form
"<Set><Member>".  All combinations having the same Member Name are adjacent
to each other in the output; for example, with Sets of ['MyApp','MyLib']
and Members of ['Eng','Fre'], the resulting list is
['MyAppEng','MyLibEng','MyAppFre','MyLibFre'].  This method is used
internally by translate_message() to produce the list of Template module
names that it will search.

=item C<translate_message( $message! )>

This method takes a (machine-readable) Message object as its positional
parameter $message and returns an equivalent human readable text message
string; this assumes that a Template corresponding to the Message could be
found using the Translator object's Set and Member properties; if none
could be matched, this method returns undef.  This method could be
considered to implement the 'main' functionality of Locale::KeyedText.

Some example usage:

    my $user_text_string = $translator->translate_message( $message );

=back

The Translator class also has these utility methods, which are all used by
translate_message() to handle the trickier parts of its work:

=over

=item C<template_module_is_loaded( $module_name! )>

This method takes the name of a Perl package in its positional parameter
$module_name (a string) and checks whether or not it has already been
loaded, returning true if so and false if not.

=item C<load_template_module( $module_name! )>

This method takes the name of a Perl package in its positional parameter
$module_name (a string) and tries to load it using 'require'.

=item C<get_template_text_from_loaded_module( $module_name!, $msg_key! )>

This method takes the name of a Perl package in its positional parameter
$module_name (a string), and a Message Key in its positional parameter
$msg_key (a string).  Assuming that a Perl module by the given module name
is already loaded, it tries to invoke $module_name.get_text_by_key(
$msg_key ) and return that subroutine's result, which is a Template text
string if the module recognizes $msg_key, and the undefined value if not.

=item C<interpolate_vars_into_template_text( $text!, %msg_vars! )>

This method takes a defined (but possibly empty) Template text string in
its positional parameter $text (a string), and a Message Variables hash ref
in its positional parameter %msg_vars.  It returns a copy of $text modified
by interpolating the %msg_vars into it, where each variable value is
substituted for any occurance of its corresponding variable name that is
bounded by '<' and '>'.  For example, given "Hello <place>!" in $text and
"{ 'place' => 'World' }" in %msg_vars, it will return "Hello World!".  All
occurances of any given variable name will be replaced, non-recursively,
and any "<foo>" not matched by a variable name will be left intact.

=back

=head1 DIAGNOSTICS

I<This documentation is pending.>

=head1 CONFIGURATION AND ENVIRONMENT

I<This documentation is pending.>

=head1 DEPENDENCIES

This file requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires these Perl 5 packages that are available both bundled with
Perl 5.8.1+ and on CPAN: L<Scalar::Util-ver(1.13..*)|Scalar::Util>.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

These Perl 5 packages work to solve similar problems as Locale::KeyedText:
L<Locale::Maketext>, L<Locale::gettext>, L<Locale::PGetText>,
L<DBIx::BabelKit>.

=head1 BUGS AND LIMITATIONS

I<This documentation is pending.>

=head1 AUTHOR

Darren Duncan (C<darren@DarrenDuncan.net>)

=head1 LICENSE AND COPYRIGHT

Locale::KeyedText is Copyright © 2003-2016, Muldis Data Systems, Inc.

L<http://www.muldis.com/>

Locale::KeyedText is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License (LGPL) as
published by the Free Software Foundation (L<http://www.fsf.org/>); either
version 3 of the License, or (at your option) any later version.  You
should have received a copy of the LGPL as part of the Locale::KeyedText
distribution, in the files named "LICENSE/LGPL" and "LICENSE/GPL" (the
LGPLv3 is defined as the terms of the GPLv3 plus extra permissions); if
not, see L<http://www.gnu.org/licenses/>.

Any versions of Locale::KeyedText that you modify and distribute must carry
prominent notices stating that you changed the files and the date of any
changes, in addition to preserving this original copyright notice and other
credits.  Locale::KeyedText is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

While it is by no means required, the copyright holder of Locale::KeyedText
would appreciate being informed any time you create a modified version of
Locale::KeyedText that you are willing to distribute, because that is a
practical way of suggesting improvements to the standard version.

=head1 ACKNOWLEDGEMENTS

=over

=item Jason Martin (C<jhmartin@toger.us>)

On 2004.07.26, suggested a feature, and provided sample usage and patch
code, that supports embedding of Template modules into the same files as
program code, rather than requiring separate files.

=item Stevan Little (C<stevan@iinteractive.com>)

On 2005.03.21, provided feedback towards improving this module's
documentation, particularly towards using a much shorter and
non-intimidating SYNOPSIS.

=back

=cut
