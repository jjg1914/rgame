class Integer
  def red_value
    # TODO ENDIAN
    (self & 0x00FF0000) >> 16
  end

  def green_value
    # TODO ENDIAN
    (self & 0x0000FF00) >> 8
  end

  def blue_value
    # TODO ENDIAN
    (self & 0x000000FF)
  end

  def alpha_value
    # TODO ENDIAN
    (self & 0xFF000000) >> 24
  end
end
