#! /usr/bin/perl -w

# Load the Module::Install bundled in ./inc/
use inc::Module::Install 0.75;

# Define metadata
name 'MooseX-AutoDoc';
abstract 'Automatically generate documentation stubs for Moose-based classes.';
all_from 'lib/MooseX/AutoDoc.pm';

# Specific dependencies
requires 'Moose'     => '0.36';
requires 'Template';  #version TBD

build_requires 'Test::More' => 0;

auto_install;
WriteAll;
