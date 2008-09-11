# Copyright (c) 2007, 2008 Pythonic Pty. Ltd. http://www.pythonic.com.au/

module ActiveRecord::ConnectionAdapters
  class AbstractAdapter
    # Yields to block inside database savepoint and retries if a duplicate
    # primary key error is raised.
    # +times+ is the number of times to retry.
    def retry_on_duplicate_primary_key(times)
      ActiveRecord::Base.silence do
        define_savepoint :retry_on_duplicate_primary_key
      end
      begin
        yield
      rescue ActiveRecord::StatementInvalid
        ActiveRecord::Base.silence do
          rollback_savepoint :retry_on_duplicate_primary_key
        end
        raise if !exception_is_duplicate_primary_key?($!)
        raise ActiveRecord::RandomizedError if times == 0
        times -= 1
        retry
      ensure
        ActiveRecord::Base.silence do
          release_savepoint :retry_on_duplicate_primary_key
        end
      end
    end
  end
end
