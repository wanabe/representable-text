require "ostruct"

RSpec.describe Representable::Text do
  it "has a version number" do
    expect(Representable::Text::VERSION).not_to be nil
  end

  shared_context "with perf line prepresenter" do
    let(:perf_line_representer) do
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

    let(:perf_line_property_names) do
      %i[
        percentage
        command
        shared_object
        symbol_type
        symbol
      ]
    end
    let(:perf_line_length_names) do
      %i[
        command_length
        shared_object_length
      ]
    end

    let(:perf_line_text) do
      "     0.32%  somecommand  [unknown]         [k] 0xffffffff814c4440"
    end
    let(:perf_line_hash) do
      {
        percentage:    "0.32",
        command:       "somecommand",
        shared_object: "[unknown]",
        symbol_type:   "k",
        symbol:        "0xffffffff814c4440",
        command_length:       11,
        shared_object_length: 16,
      }
    end
  end

  shared_context "with perf event prepresenter" do
    include_context "with perf line prepresenter"

    let(:perf_event_representer) do
      perf_line_representer = self.perf_line_representer

      Class.new(Representable::Decorator) do
        include Representable::Text

        pattern /^# Samples: .* of event '/
        property :event, /[^']*/
        pattern /'\n/
        pattern /^# Event count[^:]*: /
        property :event_count, /\d+/
        pattern /\n/
        pattern /^(?:#.*\n)*/
        collection :lines, /\n/, decorator: perf_line_representer, class: OpenStruct
      end
    end

    let(:perf_event_property_names) do
      %i[
        event
        event_count
      ]
    end
    let(:perf_event_collection_names) do
      %i[
        lines
      ]
    end

    let(:perf_event_text) do
      <<~EOT
        # Samples: 185K of event 'cycles:ppp'
        # Event count (approx.): 159224514236
        #
        # Overhead  Command         Shared Object             Symbol                                              
        # ........  ..............  ........................  ....................................................
        #
            16.47%  ruby            ruby                      [.] vm_exec_core
             3.39%  ruby            libc-2.27.so              [.] __malloc_usable_size
      EOT
    end

    let(:perf_event_hash) do
      {
        event: "cycles:ppp",
        event_count: "159224514236",
        lines: [
          { command: "ruby", command_length: 14, percentage: "16.47", shared_object: "ruby",         shared_object_length: 24, symbol: "vm_exec_core",              symbol_type: "."},
          { command: "ruby", command_length: 14, percentage:  "3.39", shared_object: "libc-2.27.so", shared_object_length: 24, symbol: "__malloc_usable_size",      symbol_type: "."},
        ]
      }
    end
  end

  describe "#from_text" do
    context "with perf line prepresenter" do
      include_context "with perf line prepresenter"

      it "gets properties" do
        perf_line = OpenStruct.new
        perf_line_representer.new(perf_line).from_text(perf_line_text)
        expect(perf_line.to_h.slice(*perf_line_property_names)).to eq(perf_line_hash.slice(*perf_line_property_names))
      end

      it "gets length properties" do
        perf_line = OpenStruct.new
        perf_line_representer.new(perf_line).from_text(perf_line_text)
        expect(perf_line.to_h.slice(*perf_line_length_names)).to eq(perf_line_hash.slice(*perf_line_length_names))
      end
    end

    context "with perf event prepresenter" do
      include_context "with perf event prepresenter"

      it "gets properties" do
        perf_event = OpenStruct.new
        perf_event_representer.new(perf_event).from_text(perf_event_text)

        expect(perf_event.to_h.slice(*perf_event_property_names)).to eq(perf_event_hash.slice(*perf_event_property_names))
      end

      it "gets collections" do
        perf_event = OpenStruct.new
        perf_event_representer.new(perf_event).from_text(perf_event_text)

        perf_event_collection_names.each do |collection_name|
          perf_event[collection_name].each_with_index do |collection_item, i|
            expect(collection_item.to_h).to eq(perf_event_hash[collection_name][i])
          end
        end
      end
    end
  end
end
