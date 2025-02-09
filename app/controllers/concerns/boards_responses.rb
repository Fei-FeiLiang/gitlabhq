# frozen_string_literal: true

module BoardsResponses
  include Gitlab::Utils::StrongMemoize

  # Overridden on EE module
  def board_params
    params.require(:board).permit(:name)
  end

  def parent
    strong_memoize(:parent) do
      group? ? group : project
    end
  end

  def boards_path
    if group?
      group_boards_path(parent)
    else
      project_boards_path(parent)
    end
  end

  def board_path(board)
    if group?
      group_board_path(parent, board)
    else
      project_board_path(parent, board)
    end
  end

  def group?
    instance_variable_defined?(:@group)
  end

  def authorize_read_list
    authorize_action_for!(board, :read_issue_board_list)
  end

  def authorize_read_issue
    authorize_action_for!(board, :read_issue)
  end

  def authorize_update_issue
    authorize_action_for!(issue, :admin_issue)
  end

  def authorize_create_issue
    list = List.find(issue_params[:list_id])
    action = list.backlog? ? :create_issue : :admin_issue

    authorize_action_for!(project, action)
  end

  def authorize_admin_list
    authorize_action_for!(board, :admin_issue_board_list)
  end

  def authorize_action_for!(resource, ability)
    return render_403 unless can?(current_user, ability, resource)
  end
end

BoardsResponses.prepend_mod_with('BoardsResponses')
