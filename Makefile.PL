#! /usr/bin/perl -w

# Load the Module::Install bundled in ./inc/
use inc::Module::Install 0.91;

# Define metadata
name 'MooseX-AutoDoc';
abstract 'Automatically generate documentation stubs for Moose-based classes.';
all_from 'lib/MooseX/AutoDoc.pm';

# Specific dependencies
requires 'Moose',                '0.89';
requires 'namespace::autoclean', '0.08';
requires 'Template';

build_requires 'Test::More' => 0;

auto_install;
WriteAll;
