require 'nokogiri'

module Hybridge
  module Batch
    class Ocr
      
      def initialize(files, package_location)
        @files = files
        @package_location = package_location
      end

      def text
        ocr_text = ""
        @files.each do |file|
          ocr_text += parse_ocr_data(file["ocr_filename"]) + "\n\n\n" if file.include?("ocr_filename")
        end
        ocr_text
      end

      def parse_ocr_data(filename)
        filepath = file_location(filename)
        output = ""
        return unless File.file? filepath

        @doc = Nokogiri::XML(File.open(filepath))
        textLine = @doc.xpath("//xmlns:TextLine")
        textLine.each do |line|
          output += "\n"
          line.xpath("xmlns:String").each do |word|
            output += word["CONTENT"] + " "
          end
        end
        output
      end

      private
      def file_location(filename)
        File.join(@package_location, filename)
      end

    end
  end
end