defmodule DummyModule do
  def example do
    "http://example.com"
  end

  def example(nth) do
    "http://example#{nth}.com"
  end
end
