Audited [![Build Status](https://secure.travis-ci.org/collectiveidea/audited.svg)](http://travis-ci.org/collectiveidea/audited) [![Dependency Status](https://gemnasium.com/collectiveidea/audited.svg)](https://gemnasium.com/collectiveidea/audited)[![Code Climate](https://codeclimate.com/github/collectiveidea/audited.svg)](https://codeclimate.com/github/collectiveidea/audited) [![Security](https://hakiri.io/github/collectiveidea/audited/master.svg)](https://hakiri.io/github/collectiveidea/audited/master)
=======

**Audited** (previously acts_as_audited) is an ORM extension that logs all changes to your models. Audited can also record who made those changes, save comments and associate models related to the changes.

Audited currently (4.x) works with Rails 5.2, 5.1, 5.0 and 4.2.

For Rails 3, use gem version 3.0 or see the [3.0-stable branch](https://github.com/collectiveidea/audited/tree/3.0-stable).

## Supported Rubies

Audited supports and is [tested against](http://travis-ci.org/collectiveidea/audited) the following Ruby versions:

* 2.3.7
* 2.4.4
* 2.5.1

Audited may work just fine with a Ruby version not listed above, but we can't guarantee that it will. If you'd like to maintain a Ruby that isn't listed, please let us know with a [pull request](https://github.com/collectiveidea/audited/pulls).

## Supported ORMs

Audited is currently ActiveRecord-only. In a previous life, Audited worked with MongoMapper. Use the [4.2-stable branch](https://github.com/collectiveidea/audited/tree/4.2-stable) if you need MongoMapper.

## Installation

Add the gem to your Gemfile:

```ruby
gem "audited", "~> 4.7"
```

Then, from your Rails app directory, create the `audits` table:

```bash
$ rails generate audited:install
$ rake db:migrate
```

If you're using PostgreSQL, then you can use `rails generate audited:install --audited-changes-column-type jsonb` (or `json`) to store audit changes natively with its JSON column types. If you're using something other than integer primary keys (e.g. UUID) for your User model, then you can use `rails generate audited:install --audited-user-id-column-type uuid` to customize the `audits` table `user_id` column type.

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

### Limiting stored audits

You can limit the number of audits stored for your model. To configure limiting for all audited models, put the following in an initializer:

```ruby
Audited.max_audits = 10 # keep only 10 latest audits
```

or customize per model:

```ruby
class User < ActiveRecord::Base
  audited max_audits: 2
end
```

Whenever an object is updated or destroyed, extra audits are combined with newer ones and the old ones are destroyed.

```ruby
user = User.create!(name: "Steve")
user.audits.count # => 1
user.update_attributes!(name: "Ryan")
user.audits.count # => 2
user.destroy
user.audits.count # => 2
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

The standard Audited install assumes your User model has an integer primary key type. If this isn't true (e.g. you're using UUID primary keys), you'll need to create a migration to update the `audits` table `user_id` column type. (See Installation above for generator flags if you'd like to regenerate the install migration.)

#### Custom Auditor

You might need to use a custom auditor from time to time. It can be done by simply passing in a string:

```ruby
class ApplicationController < ActionController::Base
  def authenticated_user
    if current_user
      current_user
    else
      'Elon Musk'
    end
  end
end
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

Now, when an audit is created for a user, that user's company is also saved alongside the audit. This makes it much easier (and faster) to access audits indirectly related to a company.

```ruby
company = Company.create!(name: "Collective Idea")
user = company.users.create!(name: "Steve")
user.update_attribute!(name: "Steve Richert")
user.audits.last.associated # => #<Company name: "Collective Idea">
company.associated_audits.last.auditable # => #<User name: "Steve Richert">
```

You can access records' own audits and associated audits in one go:
```ruby
company.own_and_associated_audits
```

### Conditional auditing

If you want to audit only under specific conditions, you can provide conditional options (similar to ActiveModel callbacks) that will ensure your model is only audited for these conditions.

```ruby
class User < ActiveRecord::Base
  audited if: :active?

  private

  def active?
    last_login > 6.months.ago
  end
end
```

Just like in ActiveModel, you can use an inline Proc in your conditions:

```ruby
class User < ActiveRecord::Base
  audited unless: Proc.new { |u| u.ninja? }
end
```

In the above case, the user will only be audited when `User#ninja` is `false`.

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

To disable auditing on all models:

```ruby
Audited.auditing_enabled = false
```

### Custom `Audit` model

If you want to extend or modify the audit model, create a new class that
inherits from `Audited::Audit`:
```ruby
class CustomAudit < Audited::Audit
  def some_custom_behavior
    "Hiya!"
  end
end
```
Then set it in an initializer:
```ruby
# config/initializers/audited.rb

Audited.config do |config|
  config.audit_class = CustomAudit
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
