# NAME

Tran - Version Control for Translation

# VERSION

Version 0.01

# DESCRIPTION

see Tran::Manaual.

# METHODS

## new

    Tran->new("/path/to/config.yml");

constructor.

## log

    $tran->log

return Tran::Log object.

## encoding

    $tran->encoding;

return encoding setting.

## resource

    $tran->resource($resource_name);

return Tran::Resource::\* object.

## resources

    $tran->resources;

return hash ref which contains resource name and resource object.

## config

    $tran->config;

return Tran::Config object.

## original\_repository

    $tran->original_repository;

return Tran::Repository::Original object.

## original

    $tran->original;

It is as same as original\_repository.

## translation\_repository

    $tran->translation_repository($translation_name);

return Tran::Repository::Translation::\* object.

    $tran->translation_repository;

return hashref which containts translation name and its object.

## notify

    $tran->notify(@notify_names, [ sub { ... }]);

Do notification according to @notify\_names.

# AUTHOR

Ktat, `<ktat at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-tran at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tran](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tran).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    man tran

You can also look for information at:

    perldoc Tran::Manual::JA

# ACKNOWLEDGEMENTS



# COPYRIGHT & LICENSE

Copyright 2010 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


