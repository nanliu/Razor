# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
   # Copyright © 2012 EMC Corporation, All Rights Reserved

module ProjectRazor
  # Used for binding of policy+models to a node
  # this is permanent unless a user removed the binding or deletes a node
  class PolicyRules
    include(ProjectRazor::Logging)
    include(Singleton)


    # Get Array of Policy Rule available
    def get_types

    end

    # Get Array of Model Configs that are compatible with a Policy Rule Type
    def get_model_configs

    end


    def get
      # Get all the policy rules
      policy_rules_array = $data.fetch_all_objects(:policy_rule)

      logger.debug "Total policy rules #{policy_rules_array.count}"
      # Sort the policy rules based on line_number
      policy_rules_array.sort! do
      |a,b|
        a.line_number <=> b.line_number
      end
      policy_rules_array
    end

    # When adding a rule
    # Line number is preserved for updates, line_number is last for new

    def add(new_policy_rule, model_config)
      existing_policy = policy_exists?(new_policy_rule)
      if existing_policy
        new_policy_rule.line_number = existing_policy.line_number
      else
        new_policy_rule.line_number = last_line_number + 1
      end
      $data.persist_object(new_policy_rule)
    end

    alias :update :add


    def remove

    end

    # Down is up in numbers (++)
    def move_lines_down

    end

    def policy_exists?(new_policy_rule)
      $data.fetch_object_by_uuid(:policy_rule, new_policy_rule)
    end

    def last_line_number
      if get.last
        get.last.line_number
      else
        0
      end
    end

  end
end