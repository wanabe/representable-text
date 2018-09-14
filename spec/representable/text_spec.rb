require "ostruct"

RSpec.describe Representable::Text do
  it "has a version number" do
    expect(Representable::Text::VERSION).not_to be nil
  end

  shared_context "with perf line prepresenter" do
    let(:representer) do
      Class.new(Representable::Decorator) do
        include Representable::Text
        right 10 do
          property :percentage, /\d+(?:\.\d+)?/
          pattern "%"
        end
        pattern "  "

        left :command_length do
          property :command, /[^ ]*/
        end
        pattern "  "

        left :shared_object_length do
          property :shared_object, /[^ ]*/
        end
        pattern "  "

        pattern "["
        property :symbol_type, /./
        pattern "] "
        property :symbol, /.*/
      end
    end

    let(:perf_line_text) { "     0.32%  somecommand  [unknown]         [k] 0xffffffff814c4440" }
  end

  describe "#from_text" do
    context "with perf line prepresenter" do
      include_context "with perf line prepresenter"

      it "gets properties" do
        perf_line = OpenStruct.new
        representer.new(perf_line).from_text(perf_line_text)
        expect(perf_line.to_h.slice(*%i[percentage command shared_object symbol_type symbol])).to eq(
          {
            percentage:    "0.32",
            command:       "somecommand",
            shared_object: "[unknown]",
            symbol_type:   "k",
            symbol:        "0xffffffff814c4440",
          }
        )
      end
    end
  end
end
