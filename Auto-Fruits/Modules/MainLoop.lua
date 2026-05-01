return {
    Start = function(Team, Collect, Store, ServerHop, ErrorHandler)
        
        task.spawn(function()
            while true do
                ErrorHandler.Wrap(function()
                    
                    Team.Join()
                    task.wait(3)
                    
                    local found = Collect.Run()
                    
                    Store.Run()
                    
                    if not found then
                        ServerHop.Run()
                    end
                    
                end)
                
                task.wait(5)
            end
        end)
        
    end
}
