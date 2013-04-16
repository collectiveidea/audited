module CommonMethods
  def return_combinations_of_actions
    actions = [:create, :destroy, :update]
    combinations = []
    for i in (1..actions.length)
      actions.combination(i).to_a.each do |action|
        combinations << action
      end 
    end
    combinations    
  end
end