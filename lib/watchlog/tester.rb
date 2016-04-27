module Watchlog
  class Tester
    PATH  = ARGV[2] || 'bin/output.log'
    attr_accessor :data

    def initialize
      @data = []
    end

    def process(hash)
      data << hash
    end

    def write
      File.open(PATH, 'w') do |f|
        f.puts "#{{ errors: data }}"
      end
    end
  end
end