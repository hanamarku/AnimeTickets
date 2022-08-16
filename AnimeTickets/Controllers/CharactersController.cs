using AnimeTickets.Models;
using AnimeTickets.Models.Services;
using AnimeTickets.Models.Static;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AnimeTickets.Controllers;
[Authorize(Roles = UserRoles.Admin)]
public class CharactersController : Controller
{

    private readonly ICharactersService _service;

    public CharactersController(ICharactersService service)
    {
        _service = service;
    }
    // GET
    [AllowAnonymous]
    public async Task<IActionResult> Index()
    {
        var data = await _service.GetAllAsync();
        return View(data);
    }

    //get : Characters/ Create
    public IActionResult Create()
    {
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> Create(Character character)
    {
        if (!ModelState.IsValid)
        {
            return View(character);
        }

        await _service.AddAsync(character);
        return RedirectToAction("Index");
    }

    //Get /Characters/Details
    [AllowAnonymous]

    public async Task<IActionResult> Details(int id)
    {
        var characterDetails = await _service.GetByIdAsync(id);
        if (characterDetails == null) return View("NotFound");
        return View(characterDetails);
    }


    //get : Characters/ Create
    public async Task<IActionResult> Edit(int id)
    {
        var characterDetails = await _service.GetByIdAsync(id);
        if (characterDetails == null) return View("NotFound");
        return View(characterDetails);
    }

    [HttpPost]
    public async Task<IActionResult> Edit(int id, Character character)
    {
        if (!ModelState.IsValid)
        {
            return View(character);
        }

        await _service.UpdateAsync(id, character);
        return RedirectToAction("Index");

    }

    //get : Characters/ Create
    public async Task<IActionResult> Delete(int id)
    {
        var characterDetails = await _service.GetByIdAsync(id);
        if (characterDetails == null) return View("NotFound");
        return View(characterDetails);
    }

    [HttpPost, ActionName("Delete")]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var character = await _service.GetByIdAsync(id);
        if (character == null) return View("NotFound");
        await _service.DeleteAsync(id);

        return RedirectToAction(nameof(Index));

    }
}