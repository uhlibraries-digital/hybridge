module Hybridge
  module Batch
    class Entry

      def initialize(work, files, collection_id, current_user, package_location)
        @work = work
        @files = files
        @collection_id = collection_id
        @current_user = current_user
        @package_location = package_location

        process!
      end

      def process!
        work_type = @work["Object Type"].constantize.new
        work_form = ("Hyrax::" + @work["Object Type"] + "Form").constantize

        work_attributes = field_attributes(work_form, work_type)

        missing = work_form.required_fields - work_attributes.keys
        if !missing.empty?
          message = "Missing required fields: #{missing.map{|m| m.to_s.inspect}.join(', ')} for '#{work_attributes[:title].first}'"
          Hyrax::MessengerService.deliver(User.batch_user, @current_user, message, "HyBridge Warning: Missing required fields")
        end

        env = Hyrax::Actors::Environment.new(work_type, Ability.new(@current_user), work_attributes)
        work_actor = Hyrax::CurationConcern.actor.create(env)

        process_files! work_type unless @files.nil?
      end

      def field_attributes(work_form, work_type)
        data = {}
        @work.each do |key, attribute|
          field_sym = field_to_sym(key)
          if (field_sym.nil? || attribute.nil? || attribute.empty? || key.to_s.include?("Object Type") || !work_form.terms.include?(field_sym))
            next
          elsif(field_sym.id2name == "based_near")
            data[:based_near_attributes] = based_near_attributes(attribute.split("||"))
          elsif(field_sym.id2name == "aspaceurl")
            url = URI.parse(attribute) rescue false
            data[field_sym] = Settings.hybridge.aspace_frontend_url + attribute unless url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS)
          elsif(field_sym.id2name == "rights_statement")
            active = Hyrax.config.rights_statement_service_class.new.active?(attribute) rescue false
            if active
              data[field_sym] = attribute
            else
              message = "Invalid/Inactive Rights Statement URL '#{attribute}' for '#{data[:title].first.to_s}'"
              Hyrax::MessengerService.deliver(User.batch_user, @current_user, message, "HyBridge Warning: Invalid/Inactive Rights Statement URL")
            end
          elsif(work_type.send(field_sym).nil?)
            data[field_sym] = attribute
          else
            data[field_sym] = attribute.split "||"
          end

          if !@collection_id.nil? && !@collection_id.empty?
            data[:member_of_collections_attributes] = {"0" => { "id" => @collection_id, "_destroy" => "false" }}
          end
        end

        ##
        # Leaving this out until a better method for OCR can be determined
        ##
        
        # if work_form.terms.include?(:transcript) && !@files.nil?
        #   data[:transcript] = Ocr.new(@files, @package_location).text[0, 20000]
        # end

        data
      end

      def based_near_attributes(values)
        based_near_values = {}
        values.each_with_index do |value, index|
          based_near_values[index.to_s] = { "id" => value, "_destroy" => "" }
        end
        based_near_values
      end

      def file_location(filename)
        File.join(@package_location, filename)
      end

      def process_files!(work_type)
        work_permissions = work_type.permissions.map(&:to_hash)
        @files.each do |file_object|
          file_path = file_location(file_object["Filename"])
          if !File.file?(file_path)
            message = "Unable to find file '#{file_object["Filename"]}' for '#{work_type[:title].first.to_s}'"
            Hyrax::MessengerService.deliver(User.batch_user, @current_user, message, "HyBridge Warning: Missing file")
            next
          end

          file_actor = Hyrax::Actors::FileSetActor.new(FileSet.create, @current_user)
          file_actor.create_metadata(alto_data: get_ocr_data(file_location(file_object["ocr_filename"]))) if file_object.include?("ocr_filename")
          file_actor.create_metadata() unless file_object.include?("ocr_filename")
          file_actor.create_content(File.new(file_path))
          file_actor.attach_to_work(work_type)
          file_actor.file_set.permissions_attributes = work_permissions
        end
      end

      def field_to_sym(field)
        if field.downcase == "abstract or summary"
          field = "description"
        elsif field.downcase == "abstract / summary"
          field = "description"
        elsif field.downcase == "location"
          field = "based_near"
        elsif field.downcase == "alternate title"
          field = "alternative"
        elsif field.downcase == "type"
          field = "resource_type"
        elsif field.downcase == "archivesspace uri"
          field = "aspaceurl"
        elsif field.downcase == "access rights"
          field = "resource_access_rights"
        elsif field.downcase == "rights"
          field = "rights_statement"
        elsif field.downcase == "collection"
          field = "provenance"
        end

        field.downcase.strip.gsub(/\s/,'_').to_sym
      end

      def get_ocr_data(filepath)
        File.read(filepath) if File.file?(filepath)
      end

    end
  end
end
