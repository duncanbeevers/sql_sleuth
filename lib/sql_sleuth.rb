module SqlSleuth
  # If a query took longer than this, log the backtrace
  SECONDS_THRESHOLD = 10
  RELEVANT_ENTITIES = [ '/app/models/', '/app/controllers/' ]
  RELEVANT_ENTITIES_EXP = Regexp.new(RELEVANT_ENTITIES.map do |e|
    "(?:#{Regexp.escape(File.join(RAILS_ROOT, e))})"
  end.join("|") + '(.*)')
  class BacktraceGenerator < StandardError
  end
end

class ActiveRecord::ConnectionAdapters::AbstractAdapter
  def log_info_with_backtrace(sql, name, *args)
    # wtf
    seconds = args.last
    if seconds >= SqlSleuth::SECONDS_THRESHOLD
      begin
        raise SqlSleuth::BacktraceGenerator
      rescue SqlSleuth::BacktraceGenerator => e
        entries = e.backtrace.map { |l| SqlSleuth::RELEVANT_ENTITIES_EXP.match(l) }.
          compact.map { |m| m[1] }.compact
        sql += '-- ' + entries.join(',') if entries.length > 0
      end
    end
    log_info_without_backtrace(sql, name, *args)
  end
  alias_method_chain :log_info, :backtrace
end
