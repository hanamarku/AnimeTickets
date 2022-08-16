using AnimeTickets.Data.Base;
using AnimeTickets.Models;
using AnimeTickets.Models.Base;
using AnimeTickets.Models.Services;
using Microsoft.EntityFrameworkCore;

namespace AnimeTickets.Data.Services;

public class CharactersService : EntityBaseRepository<Character>, ICharactersService
{

    public CharactersService(AppDbContext context) : base(context) { }
    
    // public async Task<IEnumerable<Character>> GetAllAsync()
    // {
    //     var result = await _context.Characters.ToListAsync();
    //     return result;
    // }
    //
    // public async Task<Character> GetByIdAsync(int id)
    // {
    //     var result = await _context.Characters.FirstOrDefaultAsync(n => n.Id == id);
    //     return result;
    // }
    //
    // public async Task AddAsync(Character character)
    // {
    //     await _context.Characters.AddAsync(character);
    //     await _context.SaveChangesAsync();
    // }
    //
    // public async Task<Character> UpdateAsync(int id, Character newCharacter)
    // {
    //     _context.Update(newCharacter);
    //     await _context.SaveChangesAsync();
    //     return newCharacter;
    // }
    //
    // public async Task DeleteAsync(int id)
    // {
    //     var result = _context.Characters.FirstOrDefault(n => n.Id == id);
    //     _context.Characters.Remove(result);
    //     await _context.SaveChangesAsync();
    // }
}