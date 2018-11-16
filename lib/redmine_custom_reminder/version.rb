module RedmineCustomReminder
  module Version
    MAJOR = 0
    MINOR = 2
    TINY = 3

    def self.revision
      path = File.join(Rails.root, 'plugins/redmine_custom_reminder')
      if File.directory?(File.join(path, '.git'))
        begin
          Dir.chdir(path) do
            revision = `#{Redmine::Scm::Adapters::GitAdapter.client_command} log --pretty=format:%h -n 1`
            return nil if revision.nil? || revision.empty?
            return revision
          end
        rescue
          #Nothing to do
        end
        nil
      end
    end

    REVISION = self.revision
    ARRAY = [MAJOR, MINOR, TINY, REVISION].compact
    STRING = ARRAY.join('.')

    def self.to_a
      ARRAY
    end

    def self.to_s
      STRING
    end
  end
end
