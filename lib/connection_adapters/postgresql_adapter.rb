# Copyright (c) 2007, 2008 Pythonic Pty. Ltd. http://www.pythonic.com.au/

module ActiveRecord::ConnectionAdapters
  class PostgreSQLAdapter
    # Returns whether exception is duplicate primary key error.
    def exception_is_duplicate_primary_key?(exception)
      exception.is_a?(ActiveRecord::StatementInvalid) && exception.to_s =~ /duplicate key( value)? violates unique constraint ".*_pkey"/
    end

    # Defines a savepoint.
    def define_savepoint(name)
      execute %(SAVEPOINT #{name};)
    end

    # Rolls back a savepoint.
    def rollback_savepoint(name)
      execute %(ROLLBACK TO SAVEPOINT #{name};)
    end

    # Releases a savepoint.
    def release_savepoint(name)
      execute %(RELEASE SAVEPOINT #{name};)
    end
  end
end
