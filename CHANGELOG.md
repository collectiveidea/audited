# Audited ChangeLog

## 4.8.0 (2018-08-19)

Breaking changes

- None

Added

- Add ability to globally disable auditing
  [#426](https://github.com/collectiveidea/audited/pull/426)
- Add `own_and_associated_audits` method to auditable models
  [#428](https://github.com/collectiveidea/audited/pull/428)
- Ability to nest `as_user` within itself
  [#450](https://github.com/collectiveidea/audited/pull/450)
- Private methods can now be used for conditional auditing
  [#454](https://github.com/collectiveidea/audited/pull/454)

Changed

- Add version to `auditable_index`
  [#427](https://github.com/collectiveidea/audited/pull/427)
- Rename audited resource revision `version` attribute to `audit_version` and deprecate `version` attribute
  [#443](https://github.com/collectiveidea/audited/pull/443)

Fixed

- None 

## 4.7.1 (2018-04-10)

Breaking changes

- None

Added

- None

Changed

- Change/deprecate `version` attribute to `audit_version` attribute
  [#443](https://github.com/collectiveidea/audited/pull/443)

Fixed

- Allow use with Rails 5.2 final

## 4.7.0 (2018-03-14)

Breaking changes

- None

Added

- Add `inverse_of: auditable` definition to audit relation
  [#413](https://github.com/collectiveidea/audited/pull/413)
- Add functionality to conditionally audit models
  [#414](https://github.com/collectiveidea/audited/pull/414)
- Allow limiting number of audits stored
  [#405](https://github.com/collectiveidea/audited/pull/405)

Changed

- Reduced db calls in `#revisions` method
  [#402](https://github.com/collectiveidea/audited/pull/402)
  [#403](https://github.com/collectiveidea/audited/pull/403)
- Update supported Ruby and Rails versions
  [#404](https://github.com/collectiveidea/audited/pull/404)
  [#409](https://github.com/collectiveidea/audited/pull/409)
  [#415](https://github.com/collectiveidea/audited/pull/415)
  [#416](https://github.com/collectiveidea/audited/pull/416)

Fixed

- Ensure that `on` and `except` options jive with `comment_required: true`
  [#419](https://github.com/collectiveidea/audited/pull/419)
- Fix RSpec matchers
  [#420](https://github.com/collectiveidea/audited/pull/420)

## 4.6.0 (2018-01-10)

Breaking changes

- None

Added

- Add functionality to undo specific audit
  [#381](https://github.com/collectiveidea/audited/pull/381)

Changed

- Removed duplicate declaration of `non_audited_columns` method
  [#365](https://github.com/collectiveidea/audited/pull/365)
- Updated `audited_changes` calculation to support Rails>=5.1 change syntax
  [#377](https://github.com/collectiveidea/audited/pull/377)
- Improve index ordering for polymorphic indexes
  [#385](https://github.com/collectiveidea/audited/pull/385)
- Update CI to test on newer versions of Ruby and Rails
  [#386](https://github.com/collectiveidea/audited/pull/386)
  [#387](https://github.com/collectiveidea/audited/pull/387)
  [#388](https://github.com/collectiveidea/audited/pull/388)
- Simplify `audited_columns` calculation
  [#391](https://github.com/collectiveidea/audited/pull/391)
- Simplify `audited_changes` calculation
  [#389](https://github.com/collectiveidea/audited/pull/389)
- Normalize options passed to `audited` method
  [#397](https://github.com/collectiveidea/audited/pull/397)

Fixed

- Fixed typo in rspec causing incorrect test failure
  [#360](https://github.com/collectiveidea/audited/pull/360)
- Allow running specs using rake
  [#390](https://github.com/collectiveidea/audited/pull/390)
- Passing an invalid version to `revision` returns `nil` instead of last version
  [#384](https://github.com/collectiveidea/audited/pull/384)
- Fix duplicate deceleration warnings
  [#399](https://github.com/collectiveidea/audited/pull/399)


## 4.5.0 (2017-05-22)

Breaking changes

- None

Added

- Support for `user_id` column to be a `uuid` type
  [#333](https://github.com/collectiveidea/audited/pull/333)

Fixed

- Fix retrieval of user from controller when populated in before callbacks
  [#336](https://github.com/collectiveidea/audited/issues/336)
- Fix column type check in serializer for Oracle DB adapter
  [#335](https://github.com/collectiveidea/audited/pull/335)
- Fix `non_audited_columns` to allow symbol names
  [#351](https://github.com/collectiveidea/audited/pull/351)

## 4.4.1 (2017-03-29)

Fixed

- Fix ActiveRecord gem dependency to permit 5.1
  [#332](https://github.com/collectiveidea/audited/pull/332)

## 4.4.0 (2017-03-29)

Breaking changes

- None

Added

- Support for `audited_changes` to be a `json` or `jsonb` column in PostgreSQL
  [#216](https://github.com/collectiveidea/audited/issues/216)
- Allow `Audited::Audit` to be subclassed by configuring `Audited.audit_class`
  [#314](https://github.com/collectiveidea/audited/issues/314)
- Support for Ruby on Rails 5.1
  [#329](https://github.com/collectiveidea/audited/issues/329)
- Support for Ruby 2.4
  [#329](https://github.com/collectiveidea/audited/issues/329)

Changed

- Remove rails-observer dependency
  [#325](https://github.com/collectiveidea/audited/issues/325)
- Undeprecated `Audited.audit_class` reader
  [#314](https://github.com/collectiveidea/audited/issues/314)

Fixed

- SQL error in Rails Conditional GET (304 caching)
  [#295](https://github.com/collectiveidea/audited/pull/295)
- Fix missing non_audited_columns= configuration setter
  [#320](https://github.com/collectiveidea/audited/issues/320)
- Fix migration generators to specify AR migration version
  [#329](https://github.com/collectiveidea/audited/issues/329)

## 4.3.0 (2016-09-17)

Breaking changes

- None

Added

- Support singular arguments for options: `on` and `only`

Fixed

- Fix auditing instance attributes if "only" option specified
- Allow private / protected callback declarations
- Do not eagerly connect to database

## 4.2.2 (2016-08-01)

- Correct auditing_enabled for STI models
- Properly set table name for mongomapper

## 4.2.1 (2016-07-29)

- Fix bug when only: is a single field.
- update gemspec to use mongomapper 0.13
- sweeper need not run observer for mongomapper
- Make temporary disabling of auditing threadsafe
- Centralize `Audited.store` as thread safe variable store

## 4.2.0 (2015-03-31)

Not yet documented.

## 4.0.0 (2014-09-04)

Not yet documented.

## 4.0.0.rc1 (2014-07-30)

Not yet documented.

## 3.0.0 (2012-09-25)

Not yet documented.

## 3.0.0.rc2 (2012-07-09)

Not yet documented.

## 3.0.0.rc1 (2012-04-25)

Not yet documented.

## 2012-04-10

- Add Audit scopes for creates, updates and destroys [chriswfx]

## 2011-10-25

- Made ignored_attributes configurable [senny]

## 2011-09-09

- Rails 3.x support
- Support for associated audits
- Support for remote IP address storage
- Plenty of bug fixes and refactoring
- [kennethkalmer, ineu, PatrickMa, jrozner, dwarburton, bsiggelkow, dgm]

## 2009-01-27

- Store old and new values for updates, and store all attributes on destroy.
- Refactored revisioning methods to work as expected

## 2008-10-10

- changed to make it work in development mode

## 2008-09-24

- Add ability to record parent record of the record being audited [Kenneth Kalmer]

## 2008-04-19

- refactored to make compatible with dirty tracking in edge rails
  and to stop storing both old and new values in a single audit

## 2008-04-18

- Fix NoMethodError when trying to access the :previous revision
  on a model that doesn't have previous revisions [Alex Soto]

## 2008-03-21

- added #changed_attributes to get access to the changes before a
  save [Chris Parker]

## 2007-12-16

- Added #revision_at for retrieving a revision from a specific
  time [Jacob Atzen]

## 2007-12-16

- Fix error when getting revision from audit with no changes
  [Geoffrey Wiseman]

## 2007-12-16

- Remove dependency on acts_as_list

## 2007-06-17

- Added support getting previous revisions

## 2006-11-17

- Replaced use of singleton User.current_user with cache sweeper
  implementation for auditing the user that made the change

## 2006-11-17

- added migration generator

## 2006-08-14

- incorporated changes from Michael Schuerig to write_attribute
  that saves the new value after every change and not just the
  first, and performs proper type-casting before doing comparisons

## 2006-08-14

- The "changes" are now saved as a serialized hash

## 2006-07-21

- initial version
