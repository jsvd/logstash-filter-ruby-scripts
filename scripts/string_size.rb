def register(params)
  @source_field = params["source_field"]
  @sizes = params["sizes"]
  @drop_size = params["drop_size"]
end

def filter(event)
  # tag if field isn't present
  if event.get(@source_field).nil?
    event.tag("#{@source_field}_not_found")
    return [event]
  end

  # set string size
  size = event.get(@source_field).size
  event.set("#{@source_field}_size", size)

  # calculate and tag size class
  return [event] unless @sizes
  size_class = size_class(size)
  event.set("#{@source_field}_size_class", size_class)

  # drop if it's the right size class
  size_class == @drop_size ? [] : [event]
end

def size_class(size)
  @sizes.each do |lower_bound, size_class|
    return size_class if size >= lower_bound.to_i
  end
end

# testing!!
test "when field exists" do
  parameters { { "source_field" => "field_A" } }
  in_event { { "field_A" => "hello" } }
  expect("the size is computed") {|events| events.first.get("field_A_size") == 5 }
end

test "when field doesn't exist" do
  parameters { { "source_field" => "field_A" } }
  in_event { { "field_B" => "hello" } }
  expect("tags as not found") {|events| events.first.get("tags").include?("field_A_not_found") }
end

test "when size classes are given" do
  parameters do
    { "source_field" => "field_A", "sizes" => { 50 => "big", 5 => "medium", 1 => "small" } }
  end
  in_event { { "field_A" => "a kind of medium sized string" } }
  expect("tagged with size class") {|events| events.first.get("field_A_size_class") == "medium" }
end

test "when drop size is set" do
  parameters do
    { "source_field" => "field_A",
      "sizes" => { 50 => "big", 5 => "medium", 1 => "small" },
      "drop_size" => "medium" }
  end
  in_event { { "field_A" => "a kind of medium sized string" } }
  expect("drops events of a certain size class") {|events| events.empty? }
end
