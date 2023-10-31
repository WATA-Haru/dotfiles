return
{
	'0ur4n05/42header.nvim',
	tag = 'v2.*',
	dependencies = {'akinsho/toggleterm.nvim'},
	event = {"BufNewFile", "BufRead"},
	config = function()
		require('toggleterm').setup{}
		--require('42header').setup{}
	end,
}
