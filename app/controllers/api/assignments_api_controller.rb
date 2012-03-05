module Api

  #=== Description
  # Allows for adding, modifying and showing users into MarkUs.
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class AssignmentsApiController < MainApiController
    # Requires nothing, does nothing
    def destroy
      # Admins should not be deleting assignments at all so pretend this URL does not exist
      render 'shared/http_status', :locals => { :code => "404", :message => HttpStatusHelper::ERROR_CODE["message"]["404"] }, :status => 404
    end
    
    # Requires nothing
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
    
    # Requires id ( short identifier )
    def show
      if params[:id].blank?
        # incomplete/invalid HTTP params
        render 'shared/http_status', :locals => { :code => "422", :message => "Missing user name" }, :status => 422
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