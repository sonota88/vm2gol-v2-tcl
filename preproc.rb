Encoding.default_external = "utf-8"
Encoding.default_internal = "utf-8"

file = ARGV[0]
dir = File.dirname(File.expand_path(file))

new_lines = []

in_include = false

File.read(file).each_line do |line|
  if m = /^#include (.+)/.match(line)
    include_target = File.join(dir, m[1])
    in_include = true
    new_lines << line
    new_lines += File.read(include_target).lines unless ENV.key?("CLEAN")
  elsif /^#end_include/ =~ line
    new_lines << "# ================================\n" unless ENV.key?("CLEAN")
    new_lines << line
    in_include = false
  else
    if in_include
      # skip
    else
      new_lines << line
    end
  end
end

File.open(file, "wb") do |f|
  f.print new_lines.join
end
