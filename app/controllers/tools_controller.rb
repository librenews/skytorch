class ToolsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tool, only: [:show, :edit, :update, :destroy]
  
  def index
    @tools = current_user.tools.order(created_at: :desc)
    @toolbox = current_user.toolbox
    @public_tools = current_user.public_tools
  end
  
  def show
    # Allow viewing public tools from other users
    unless @tool.visibility == 'public' || @tool.user == current_user
      redirect_to tools_path, alert: 'Tool not found'
    end
  end
  
  def new
    @tool = current_user.tools.build
  end
  
  def create
    @tool = current_user.tools.build(tool_params)
    
    if @tool.save
      redirect_to @tool, notice: 'Tool was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    redirect_to tools_path, alert: 'Not authorized' unless @tool.user == current_user
  end
  
  def update
    redirect_to tools_path, alert: 'Not authorized' unless @tool.user == current_user
    
    if @tool.update(tool_params)
      redirect_to @tool, notice: 'Tool was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    redirect_to tools_path, alert: 'Not authorized' unless @tool.user == current_user
    
    @tool.destroy
    redirect_to tools_path, notice: 'Tool was successfully deleted.'
  end
  
  def discover
    @query = params[:q]
    @tool_type = params[:type]
    @tools = ToolService.new(current_user).discover_tools(@query, type: @tool_type)
  end
  
  def add_to_toolbox
    tool = Tool.find(params[:id])
    current_user.add_to_toolbox(tool)
    redirect_to tools_path, notice: 'Tool added to toolbox.'
  end
  
  private
  
  def set_tool
    @tool = Tool.find(params[:id])
  end
  
  def tool_params
    params.require(:tool).permit(:name, :description, :tool_type, :visibility, tags: [], definition: {})
  end
end



