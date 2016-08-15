Audited [![Build Status](https://secure.travis-ci.org/collectiveidea/audited.svg)](http://travis-ci.org/collectiveidea/audited) [![Dependency Status](https://gemnasium.com/collectiveidea/audited.svg)](https://gemnasium.com/collectiveidea/audited)[![Code Climate](https://codeclimate.com/github/collectiveidea/audited.svg)](https://codeclimate.com/github/collectiveidea/audited) [![Security](https://hakiri.io/github/collectiveidea/audited/master.svg)](https://hakiri.io/github/collectiveidea/audited/master)
=======

> ## Important version disclaimer
> ***This README is for a branch which is still in development.
> Please switch to the [4.2-stable branch](https://github.com/collectiveidea/audited/tree/4.2-stable) for a stable version.***

**Audited** (previously acts_as_audited) is an ORM extension that logs all changes to your models. Audited also allows you to record who made those changes, save comments and associate models related to the changes.

Audited currently (4.x) works with Rails 5.0 and 4.2. It also may work with 4.1 and 4.0, but this is not guaranteed.

For Rails 3, use gem version 3.0 or see the [3.0-stable branch](https://github.com/collectiveidea/audited/tree/3.0-stable).

## Supported Rubies

Audited supports and is [tested against](http://travis-ci.org/collectiveidea/audited) the following Ruby versions:

* 2.1.5
* 2.2.4
* 2.3.0

Audited may work just fine with a Ruby version not listed above, but we can't guarantee that it will. If you'd like to maintain a Ruby that isn't listed, please let us know with a [pull request](https://github.com/collectiveidea/audited/pulls).

## Supported ORMs

Audited is currently ActiveRecord-only. In a previous life, Audited worked with MongoMapper. Use the [4.2-stable branch](https://github.com/collectiveidea/audited/tree/4.2-stable) if you need MongoMapper.

## Installation

Add the gem to your Gemfile:

```ruby
gem "audited", "~> 4.0"
```

If you are using rails 5.0, you would also need the following line in your Gemfile.
```ruby
gem "rails-observers", github: 'rails/rails-observers'
```

Then, from your Rails app directory, create the `audits` table:

```bash
$ rails generate audited:install
$ rake db:migrate
```

#### Upgrading

If you're already using Audited (or acts_as_audited), your `audits` table may require additional columns. After every upgrade, please run:

```bash
$ rails generate audited:upgrade
$ rake db:migrate
```

Upgrading will only make changes if changes are needed.


## Usage

Simply call `audited` on your models:

```ruby
class User < ActiveRecord::Base
  audited
end
```

By default, whenever a user is created, updated or destroyed, a new audit is created.

```ruby
user = User.create!(name: "Steve")
user.audits.count # => 1
user.update_attributes!(name: "Ryan")
user.audits.count # => 2
user.destroy
user.audits.count # => 3
```

Audits contain information regarding what action was taken on the model and what changes were made.

```ruby
user.update_attributes!(name: "Ryan")
audit = user.audits.last
audit.action # => "update"
audit.audited_changes # => {"name"=>["Steve", "Ryan"]}
```

You can get previous versions of a record by index or date, or list all
revisions.

```ruby
user.revisions
user.revision(1)
user.revision_at(Date.parse("2016-01-01"))
```

### Specifying columns

By default, a new audit is created for any attribute changes. You can, however, limit the columns to be considered.

```ruby
class User < ActiveRecord::Base
  # All fields
  # audited

  # Single field
  # audited only: :name

  # Multiple fields
  # audited only: [:name, :address]

  # All except certain fields
  # audited except: :password
end
```

### Specifying callbacks

By default, a new audit is created for any Create, Update or Destroy action. You can, however, limit the actions audited.

```ruby
class User < ActiveRecord::Base
  # All fields and actions
  # audited

  # Single field, only audit Update and Destroy (not Create)
  # audited only: :name, on: [:update, :destroy]
end
```

### Comments

You can attach comments to each audit using an `audit_comment` attribute on your model.

```ruby
user.update_attributes!(name: "Ryan", audit_comment: "Changing name, just because")
user.audits.last.comment # => "Changing name, just because"
```

You can optionally add the `:comment_required` option to your `audited` call to require comments for all audits.

```ruby
class User < ActiveRecord::Base
  audited :comment_required => true
end
```

### Current User Tracking

If you're using Audited in a Rails application, all audited changes made within a request will automatically be attributed to the current user. By default, Audited uses the `current_user` method in your controller.

```ruby
class PostsController < ApplicationController
  def create
    current_user # => #<User name: "Steve">
    @post = Post.create(params[:post])
    @post.audits.last.user # => #<User name: "Steve">
  end
end
```

To use a method other than `current_user`, put the following in an initializer:

```ruby
Audited.current_user_method = :authenticated_user
```

Outside of a request, Audited can still record the user with the `as_user` method:

```ruby
Audited.audit_class.as_user(User.find(1)) do
  post.update_attribute!(title: "Hello, world!")
end
post.audits.last.user # => #<User id: 1>
```

### Associated Audits

Sometimes it's useful to associate an audit with a model other than the one being changed. For instance, given the following models:

```ruby
class User < ActiveRecord::Base
  belongs_to :company
  audited
end

class Company < ActiveRecord::Base
  has_many :users
end
```

Every change to a user is audited, but what if you want to grab all of the audits of users belonging to a particular company? You can add the `:associated_with` option to your `audited` call:

```ruby
class User < ActiveRecord::Base
  belongs_to :company
  audited associated_with: :company
end

class Company < ActiveRecord::Base
  has_many :users
  has_associated_audits
end
```

Now, when a audit is created for a user, that user's company is also saved alongside the audit. This makes it much easier (and faster) to access audits indirectly related to a company.

```ruby
company = Company.create!(name: "Collective Idea")
user = company.users.create!(name: "Steve")
user.update_attribute!(name: "Steve Richert")
user.audits.last.associated # => #<Company name: "Collective Idea">
company.associated_audits.last.auditable # => #<User name: "Steve Richert">
```

### Disabling auditing

If you want to disable auditing temporarily doing certain tasks, there are a few
methods available.

To disable auditing on a save:

```ruby
@user.save_without_auditing
```

or:

```ruby
@user.without_auditing do
  @user.save
end
```

To disable auditing on a column:

```ruby
User.non_audited_columns = [:first_name, :last_name]
```

To disable auditing on an entire model:

```ruby
User.auditing_enabled = false
```

### Asynchronous Auditing

To create audit records asynchronously, you need to tell Audited which
adapter to use by setting `Audited.async_class`. Here is an example
`config/initializers/audited.rb`:

```ruby
if Rails.env.test?
  Audited.async_class = Audited::Async::Synchronous
else
  Audited.async_class = Audited::Async::Resque
  # The default queue name is :audit. To specify your own, do this:
  Audited::Async::Resque.queue = :my_queue
end
```

In your model, set `async` to true:

```ruby
class User < ActiveRecord::Base
  audited async: true
end
```

There are two adapter currently available: `Audited::Async::Resque` and
`Audited::Async::Synchronous`. The Resque adapter's default queue name is
`:audit`. The latter is mostly used for testing, since it synchronously
creates all audits passed to it.

Using asynchronous auditing will trigger a deprecation warning in some
versions of Rails related to the use of `after_commit`. The warning
describes the issue and includes directions on how to opt in to the new
behaviour and remove the warning:

```ruby
config.active_record.raise_in_transactional_callbacks = true
```

#### Behind the Scenes

When an audit records should be created, its attributes are put into a
class-level array. On commit, that array is sent to the async adapter for
processing.

If the adapter raises an error when trying to enqueue audits, the audits are
written synchronously instead.

#### Creating an Async Adapter

Each Audited::Async adapter must implemented an `enqueue` class method that
takes two arguments: the name of the audit class to instantiate and an array
of audit creation attribute hashes. For each attribute hash, it should
asynchronously create the audit record from the class and attributes. Here's
an example:

```ruby
module Audited
  module Async
    class Resque
      @queue = :audit

      def self.enqueue(klass_name, audits_attrs)
        Resque.enqueue(self, klass_name, audits_attrs)
      end

      # Takes a model `klass` and an array of hashes of audit `attrs` and
      # creates audit records from them.
      def self.perform(klass_name, audits_attrs)
        klass = Module.const_get(klass_name)
        audits_attrs.each do |attrs|
          klass.create(attrs)
        end
      end
    end
  end
end
```

When adding an adapter, make sure to add it to the list of autoloads in
`lib/audited/audit.rb`.

### Disabling Asynchronous Auditing

If you want to disable asynchronous auditing, forcing audit records to be
created synchronously, while temporarily doing certain tasks there are a few
methods available.

To disable async auditing on a save:

```ruby
@user.save_without_async_auditing
```

or:

```ruby
@user.without_async_auditing do
  @user.save
end
```

To disable asyncronous auditing on an entire model:

```ruby
User.async_enabled = false
```

## Gotchas

### Using attr_protected with Rails 4.x

If you're using the `protected_attributes` gem with Rails 4.0, 4.1 or 4.2 (the gem isn't supported in Rails 5.0 or higher), you'll have to take an extra couple of steps to get `audited` working.

First be sure to add `allow_mass_assignment: true` to your `audited` call; otherwise Audited will
interfere with `protected_attributes` and none of your `save` calls will work.

```ruby
class User < ActiveRecord::Base
  audited allow_mass_assignment: true
end
```

Second, be sure to add `audit_ids` to the list of protected attributes to prevent data loss.

```ruby
class User < ActiveRecord::Base
  audited allow_mass_assignment: true
  attr_protected :logins, :audit_ids
end
```

## Support

You can find documentation at: http://rdoc.info/github/collectiveidea/audited

Or join the [mailing list](http://groups.google.com/group/audited) to get help or offer suggestions.

## Contributing

In the spirit of [free software](http://www.fsf.org/licensing/essays/free-sw.html), **everyone** is encouraged to help improve this project. Here are a few ways _you_ can pitch in:

* Use prerelease versions of Audited.
* [Report bugs](https://github.com/collectiveidea/audited/issues).
* Fix bugs and submit [pull requests](http://github.com/collectiveidea/audited/pulls).
* Write, clarify or fix documentation.
* Refactor code.
