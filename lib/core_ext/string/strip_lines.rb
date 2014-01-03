class String
  def strip_lines
    strip.split("\n").map(&:strip).join("\n")
  end
end
