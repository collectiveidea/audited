Audited [![Build Status](https://secure.travis-ci.org/collectiveidea/audited.png)](http://travis-ci.org/collectiveidea/audited) [![Dependency Status](https://gemnasium.com/collectiveidea/audited.png)](https://gemnasium.com/collectiveidea/audited)
=======

**Audited** (previously acts_as_audited) is an ORM extension that logs all changes to your models. Audited also allows you to record who made those changes, save comments and associate models related to the changes. Audited works with Rails 3.

## Supported Rubies

Audited supports and is [tested against](http://travis-ci.org/collectiveidea/audited) the following Ruby versions:

* 1.8.7
* 1.9.2
* 1.9.3
* Head

Audited may work just fine with a Ruby version not listed above, but we can't guarantee that it will. If you'd like to maintain a Ruby that isn't listed, please let us know with a [pull request](https://github.com/collectiveidea/audited/pulls).

## Supported ORMs

In a previous life, Audited was ActiveRecord-only. Audited will now audit models for the following backends:

* ActiveRecord
* MongoMapper

## Installation

The installation process depends on what ORM your app is using.

### ActiveRecord

Add the appropriate gem to your Gemfile:

```ruby
gem "audited-activerecord", "~> 3.0"
```

Then, from your Rails app directory, create the `audits` table:

```bash
$ rails generate audited:install
$ rake db:migrate
```

### MongoMapper

```ruby
gem "audited-mongo_mapper", "~> 3.0"
```

## Upgrading

If you're already using Audited (or acts_as_audited), your `audits` table may require additional columns. After every upgrade, please run:

```bash
$ rails generate audited:upgrade
```

This will only make changes if changes are needed.

## Usage

Simply call `audited` on your models:

```ruby
class User < ActiveRecord::Base
  audited
end
```

## TODO: Moar Usage

## TODO: Caveats?

## TODO: Support (documentation and Google group)

## TODO: Contributing
