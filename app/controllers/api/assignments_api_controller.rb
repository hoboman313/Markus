module Api
  #=== Description
  # Allows for adding, modifying and showing assignments for MarkUs.
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class AssignmentsApiController < MainApiController
    # Accepts: short_identifier, due_date ( YYYY-MM-DD HH:MM ), [repository_folder] ( default: same as short_identifier ),
    # [group_min] ( default: 1 ), [group_max] ( default: 1 ), [tokens_per_day] ( default: 0 ),
    # [submission_rule_type] ( default: noLateSubmissionRule ), [marking_scheme_type] ( default: rubric ),
    # [allow_web_submits] ( default: 1 ), [display_grader_names_to_students] ( default: 0 ),
    # [enable_test] ( default: 0 ), [assign_graders_to_criteria] ( default: 0 )
    # [description], [message], [allow_remarks] ( default: 1 ), [remark_due_date]
    # [remark_message], [student_form_groups] ( default: 0 ),
    # [group_name_autogenerated] ( default: 1 ), [submission_rule_deduction],
    # [submission_rule_hours] ( REQUIRED if submission_rule_type is not noLateSubmissionRule ),
    # [submission_rule_interval]
    def create
      if has_missing_params?(params)
        # incomplete/invalid HTTP params
        render 'shared/http_status', :locals => { :code => "422", :message => HttpStatusHelper::ERROR_CODE["message"]["422"] }, :status => 422
      return
      end

      # check if there is an existing assignment
      assignment = Assignment.find_by_short_identifier(params[:short_identifier])
      if !assignment.nil?
        render 'shared/http_status', :locals => { :code => "409", :message => "Assignment already exists" }, :status => 409
      return
      end

      # no assignment found so create a new one
      attributes={:short_identifier => params[:short_identifier]}
      attributes = process_attributes(params, attributes, true)

      new_assignment = Assignment.new(attributes)
      new_assignment.build_assignment_stat

      @submission_rule = get_submission_rule(params)
      # stop if we encountered an error while getting the submission_rule
      if !@submission_rule
        return
      end
      new_assignment.submission_rule = @submission_rule

      if !new_assignment.save
        # some error occurred
        render 'shared/http_status', :locals => { :code => "500", :message => HttpStatusHelper::ERROR_CODE["message"]["500"] +
          ": " + new_assignment.errors.full_messages.join(", ")}, :status => 500
      return
      end

      # otherwise everything went well
      render 'shared/http_status', :locals => { :code => "200", :message => HttpStatusHelper::ERROR_CODE["message"]["200"] }, :status => 200
    end

    # Accepts: nothing
    def destroy
      # Admins should not be deleting assignments at all so pretend this URL does not exist
      render 'shared/http_status', :locals => { :code => "404", :message => HttpStatusHelper::ERROR_CODE["message"]["404"] }, :status => 404
    end

    # Accepts: [short_identifier], [due_date] ( YYYY-MM-DD HH:MM ), [repository_folder] ( default: same as short_identifier ),
    # [group_min] ( default: 1 ), [group_max] ( default: 1 ), [tokens_per_day] ( default: 0 ),
    # [submission_rule_type] ( default: noLateSubmissionRule ), [marking_scheme_type] ( default: rubric ),
    # [allow_web_submits] ( default: 1 ), [display_grader_names_to_students] ( default: 0 ),
    # [enable_test] ( default: 0 ), [assign_graders_to_criteria] ( default: 0 )
    # [description], [message], [allow_remarks] ( default: 1 ), [remark_due_date]
    # [remark_message], [student_form_groups] ( default: 0 ),
    # [group_name_autogenerated] ( default: 1 ), [submission_rule_deduction],
    # [submission_rule_hours] ( REQUIRED if submission_rule_type is not noLateSubmissionRule ),
    # [submission_rule_interval]
    def update
      # If no assignment is found, render an error.
      assignment = Assignment.find_by_short_identifier(params[:id])
      if assignment.nil?
        render 'shared/http_status', :locals => { :code => "404", :message => "Assignment was not found" }, :status => 404
        return
      end

      updated_short_identifier = params[:id]
      if !params[:short_identifier].blank?
        # Make sure new short_identifier does not exist
        if !Assignment.find_by_short_identifier(params[:short_identifier]).nil?
          render 'shared/http_status', :locals => { :code => "409", :message => "An assignment already exists with the specified short_identifier" }, :status => 409
        return
        end
        updated_short_identifier = params[:short_identifier]
      end

      attributes={:short_identifier => updated_short_identifier}
      attributes = process_attributes(params, attributes, false)

      @submission_rule = get_submission_rule(params)
      # stop if we encountered an error while getting the submission_rule
      if !@submission_rule
        return
      end

      assignment.transaction do
        # make sure to delete all the old submission rule first
        assignment.submission_rule.destroy

        assignment.submission_rule = @submission_rule
        assignment.attributes = attributes
        if !assignment .save
          # Some error occurred
          render 'shared/http_status', :locals => { :code => "500", :message => HttpStatusHelper::ERROR_CODE["message"]["500"] +
            ": " + assignment.errors.full_messages.join(", ") }, :status => 500
        return
        end
      end

      # Otherwise everything went well
      render 'shared/http_status', :locals => { :code => "200", :message => HttpStatusHelper::ERROR_CODE["message"]["200"] }, :status => 200
      return
    end

    # Accepts: nothing
    def index
      assignments = Assignment.all

      respond_to do |format|
        format.any{render :text => get_plain_text_for_assignments(assignments)}
        format.json{render :json => assignments.to_json(:only => [ :short_identifier, :due_date,
           :marking_scheme_type, :allow_web_submits, :display_grader_names_to_students, :type ], :include => :submission_rule)}
        format.xml{render :xml => assignments.to_xml(:only => [ :short_identifier, :due_date,
          :marking_scheme_type, :allow_web_submits, :display_grader_names_to_students, :type ], :include => :submission_rule)}
      end
    end

    # Accepts: id ( short identifier )
    def show
      if params[:id].blank?
        # incomplete/invalid HTTP params
        render 'shared/http_status', :locals => { :code => "422", :message => "Missing short identifier name" }, :status => 422
      return
      end

      # check if there's a valid assignment
      assignment = Assignment.find_by_short_identifier(params[:id])
      if assignment.nil?
        # no such assignment
        render 'shared/http_status', :locals => { :code => "404", :message => "Assignment was not found" }, :status => 404
      return
      end

      # Everything went fine, send the response according to the user's format
      respond_to do |format|
        format.any{render :text => get_plain_text_for_assignments([assignment])}
        format.json{render :json => assignment.to_json(:only => [ :short_identifier, :due_date,
           :marking_scheme_type, :allow_web_submits, :display_grader_names_to_students,:enable_test,
           :assign_graders_to_criteria, :type ], :include => :submission_rule)}
        format.xml{render :xml => assignment.to_xml(:only => [ :short_identifier, :due_date,
           :marking_scheme_type, :allow_web_submits, :display_grader_names_to_students,:enable_test,
           :assign_graders_to_criteria, :type ], :include => :submission_rule)}
      end
    end

    private

    def get_submission_rule(params)
      if params[:submission_rule_type].nil? or params[:submission_rule_type] == "NoLate"
        @submission_rule = NoLateSubmissionRule.new

      elsif params[:submission_rule_type] == "GracePeriod"
        @submission_rule = GracePeriodSubmissionRule.new
        @submission_rule.periods.push( Period.new( :hours => params[:submission_rule_hours]))

      elsif params[:submission_rule_type] == "PenaltyDecayPeriod"
        @submission_rule = PenaltyDecayPeriodSubmissionRule.new
        @submission_rule.periods.push( Period.new( :hours => params[:submission_rule_hours],
        :deduction => params[:submission_rule_deduction], :interval => params[:submission_rule_interval]))

      elsif params[:submission_rule_type] == "PenaltyPeriod"
        @submission_rule = PenaltyPeriodSubmissionRule.new
        @submission_rule.periods.push( Period.new( :hours => params[:submission_rule_hours], :deduction => params[:submission_rule_deduction]))

      else
        render 'shared/http_status', :locals => { :code => "422", :message => "Unrecognized submission_rule_type"}, :status => 422
      @submission_rule = false
      end

      return @submission_rule
    end

    # Process the parameters passed during a POST/PUT request
    def process_attributes(params, attributes, create)
      attributes["due_date"] = params[:due_date] if !params[:due_date].nil?
      attributes["group_min"] = params[:group_min] if !params[:group_min].nil?
      attributes["group_max"] = params[:group_max] if !params[:group_max].nil?
      attributes["tokens_per_day"] = params[:tokens_per_day] if !params[:tokens_per_day].nil?
      attributes["marking_scheme_type"] = params[:marking_scheme_type] if !params[:marking_scheme_type].nil?
      attributes["description"] = params[:description] if !params[:description].nil?
      attributes["message"] = params[:message] if !params[:message].nil?
      attributes["allow_remarks"] = params[:allow_remarks] if !params[:allow_remarks].nil?
      attributes["remark_due_date"] = params[:remark_due_date] if !params[:remark_due_date].nil?
      attributes["remark_message"] = params[:remark_message] if !params[:remark_message].nil?
      attributes["student_form_groups"] = params[:student_form_groups] if !params[:student_form_groups].nil?
      attributes["group_name_autogenerated"] = params[:group_name_autogenerated] if !params[:group_name_autogenerated].nil?

      # These attributes HAVE to be set when creating a new assignment for the model to save correctly, but
      # have default values that are usually preset in the UI. They do need to be set when editing an existing
      # assignment
      if create
        attributes["allow_web_submits"] = params[:allow_web_submits].nil? ? 1 : params[:allow_web_submits]
        attributes["display_grader_names_to_students"] = params[:display_grader_names_to_students].nil? ? 1 : params[:display_grader_names_to_students]
        attributes["enable_test"] = params[:enable_test].nil? ? 1 : params[:enable_test]
        attributes["assign_graders_to_criteria"] = params[:assign_graders_to_criteria].nil? ? 1 : params[:assign_graders_to_criteria]
        attributes["repository_folder"] = params[:repository_folder].nil? ? attributes[:short_identifier] : params[:repository_folder]
      else
        attributes["allow_web_submits"] = params[:allow_web_submits] if !params[:allow_web_submits].nil?
        attributes["display_grader_names_to_students"] =  params[:display_grader_names_to_students] if !params[:display_grader_names_to_students].nil?
        attributes["enable_test"] = params[:enable_test] if !params[:enable_test].nil?
        attributes["assign_graders_to_criteria"] = params[:assign_graders_to_criteria] if !params[:assign_graders_to_criteria].nil?
        attributes["repository_folder"] = params[:repository_folder] if !params[:repository_folder].nil?
      end

      return attributes
    end

    # Checks short_identifier, due_date
    def has_missing_params?(params)
      return params[:short_identifier].blank? || params[:due_date].blank?
    end

    # Get the plain text representation for users
    def get_plain_text_for_assignments(assignments)
      data=""

      assignments.each do |assignment|
        data += t('short_identifier') + ": " + assignment.short_identifier + "\n" +
        t('due_date') + ": " + assignment.due_date.to_s + "\n" +
        t('assignment.allow_web_submits') + ": " + assignment.allow_web_submits.to_s + "\n" +
        t('assignment.display_grader_names_to_students') + ": " + assignment.display_grader_names_to_students.to_s + "\n" +
        t('automated_tests.enable_test') + ": " + assignment.enable_test.to_s + "\n" +
        t('graders.assign_to_criteria') + ": " + assignment.assign_graders_to_criteria.to_s + "\n" +
        t('assignment.marking_scheme.title') + ": " + assignment.marking_scheme_type.to_s + "\n" +
        t('assignment.submission_rules') + ": " + assignment.submission_rule.type + "\n\n"
      end

      return data
    end

  end # end AssignmentsApiController
end