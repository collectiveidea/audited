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

#### Upgrading

If you're already using Audited (or acts_as_audited), your `audits` table may require additional columns. After every upgrade, please run:

```bash
$ rails generate audited:upgrade
$ rake db:migrate
```

Upgrading will only make changes if changes are needed.

### MongoMapper

```ruby
gem "audited-mongo_mapper", "~> 3.0"
```

## Usage

Simply call `audited` on your models:

```ruby
class User < ActiveRecord::Base
  audited
end
```

By default, whenever a user is created, updated or destroyed, a new audit is created.

```ruby
user = User.create!(:name => "Steve")
user.audits.count # => 1
user.update_attributes!(:name => "Ryan")
user.audits.count # => 2
user.destroy
user.audits.count # => 3
```

Audits contain information regarding what action was taken on the model and what changes were made.

```ruby
user.update_attributes!(:name => "Ryan")
audit = user.audits.last
audit.action # => "update"
audit.audited_changes # => {"name"=>["Steve", "Ryan"]}
```

### Comments

You can attach comments to each audit using an `audit_comment` attribute on your model.

```ruby
user.update_attributes!(:name => "Ryan", :audit_comment => "Changing name, just because")
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

```
class PostsController < ApplicationController
  def create
    current_user # => #<User name: "Steve">
    @post = Post.create(params[:post])
    @post.audits.last.user # => #<User name: "Steve">
  end
end
```

To use a method other than `current_user`, put the following in an intializer:

```ruby
Audited.current_user_method = :authenticated_user
```

Outside of a request, Audited can still record the user with the `as_user` method:

```ruby
Audit.as_user(User.find(1)) do
  post.update_attribute!(:title => "Hello, world!")
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
  audited :associated_with => :company
end

class Company < ActiveRecord::Base
  has_many :users
  has_associated_audits
end
```

Now, when a audit is created for a user, that user's company is also saved alongside the audit. This makes it much easier (and faster) to access audits indirectly related to a company.

```ruby
company = Company.create!(:name => "Collective Idea")
user = company.users.create!(:name => "Steve")
user.update_attribute!(:name => "Steve Richert")
user.audits.last.associated # => #<Company name: "Collective Idea">
company.associated_audits.last.auditable # => #<User name: "Steve Richert">
```

## Gotchas

### Accessible Attributes

Audited assumes you are using `attr_accessible`, however, if you are using `attr_protected` or just going at it unprotected you will have to set the `:allow_mass_assignment => true` option.

If using `attr_protected` be sure to add `audit_ids` to the list of protected attributes to prevent data loss.

```ruby
class User < ActiveRecord::Base
  audited :allow_mass_assignment => true
end
```

```ruby
class User < ActiveRecord::Base
  audited :allow_mass_assignment => true
  attr_protected :logins, :audit_ids
end
```

### MongoMapper Embedded Documents

Currently, Audited does not track changes on embedded documents. Audited works by tracking a model's [dirty changes](http://api.rubyonrails.org/classes/ActiveModel/Dirty.html) but changes to embedded documents don't appear in dirty tracking.

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
