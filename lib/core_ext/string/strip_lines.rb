class String
  def strip_lines
    split("\n").map(&:strip).join("\n")
  end
end
