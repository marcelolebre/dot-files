return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true, -- show dotfiles (e.g. .gitkeep)
          ignored = true, -- show gitignored files (e.g. audits/*.md)
        },
      },
    },
  },
}
