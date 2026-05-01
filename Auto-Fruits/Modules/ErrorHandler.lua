return {
    Wrap = function(func)
        local success, err = pcall(func)
        if not success then
            warn("Erro:", err)
        end
    end
}
