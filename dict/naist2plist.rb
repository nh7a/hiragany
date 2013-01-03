# encoding: utf-8
require 'nkf'

$entries = {}
$dups = {}

def new_item(yomi, midashi)
  return if midashi.length == 1
  return if $dups.include? yomi
  if $entries.include? yomi
    $dups[yomi] = true
    $entries.delete(yomi)
  else
    $entries[yomi] = midashi
  end
end

def print_plist(items)
  puts <<EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
EOT
  items.sort.each {|i|
    yomi = NKF.nkf('-h1 -w', i[0])
    next unless yomi =~ /^[\p{hiragana}]+$/
    next if yomi.length < 3
    next if i[1] =~ /[\p{hiragana}\p{katakana}]+/
    puts "<key>#{yomi}</key><string>#{i[1]}</string>"
  }
  puts "</dict>\n</plist>"
end

while line = gets
#  next unless line =~ /\(名詞 一般\)/
#  next unless line =~ /\(名詞 /
  next if line =~ /固有名詞/
  yomi = line.match(/\(読み ([^\)]+)\)/)[1]
  midashi = line.match(/\(\(見出し語 \((.+) \d+\)\)/)[1]

  if yomi.include?('/')
    yomi[1..-2].split('/').each {|i|
      new_item(i, midashi)
    }
  else
    new_item(yomi, midashi)
  end
end

print_plist($entries)
