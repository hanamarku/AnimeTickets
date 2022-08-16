using AnimeTickets.Models.Base;

namespace AnimeTickets.Models.Services;

public interface ICharactersService: IEntityaBaseRepository<Character>
{
    // Task<IEnumerable<Character>>  GetAllAsync();
    //
    // Task<Character> GetByIdAsync(int id);
    //
    // Task AddAsync(Character character);
    //
    // Task<Character> UpdateAsync(int id, Character newCharacter);
    //
    // Task DeleteAsync(int id);
}