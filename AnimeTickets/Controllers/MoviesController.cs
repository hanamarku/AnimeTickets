using AnimeTickets.Data.Services;
using AnimeTickets.Models;
using AnimeTickets.Models.Static;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace AnimeTickets.Controllers;
[Authorize(Roles = UserRoles.Admin)]
public class MoviesController : Controller
{
    private readonly IMovieService _service;

    public MoviesController(IMovieService service)
    {
        _service = service;
    }
    // GET
    [AllowAnonymous]
    public async Task<IActionResult> Index()
    {
        var movies = await _service.GetAllAsync(n => n.Cinema);
        return View(movies);
    }
    [AllowAnonymous]
    public async Task<IActionResult> Filter(string searchString)
    {
        var movies = await _service.GetAllAsync(n => n.Cinema);
        if (!string.IsNullOrEmpty(searchString))
        {
            var filteredResult = movies.Where(n => n.Name.ToLower().ToString().Contains(searchString.ToLower())
                                                   || n.Description.Contains(searchString.ToLower())).ToList();
            return View("Index", filteredResult);
        }
        return View("Index", movies);
    }

    //Get: movies/details
    [AllowAnonymous]
    public async Task<IActionResult> Details(int id)
    {
        var movieDetail = await _service.GetMovieByIdAsync(id);
        return View(movieDetail);
    }

    //Get: Movies/Create

    public async Task<IActionResult> Create()
    {
        var movieDropdownData = await _service.GetMovieDropdownsValues();
        ViewBag.Cinemas = new SelectList(movieDropdownData.Cinemas, "Id", "Name");
        ViewBag.Producers = new SelectList(movieDropdownData.Producers, "Id", "FullName");
        ViewBag.Characters = new SelectList(movieDropdownData.Characters, "Id", "FullName");

        return View();
    }

    [HttpPost]
    public async Task<IActionResult> Create(NewMovieVM movie)
    {
        if (!ModelState.IsValid)
        {
            var movieDropdownData = await _service.GetMovieDropdownsValues();
            ViewBag.Cinemas = new SelectList(movieDropdownData.Cinemas, "Id", "Name");
            ViewBag.Producers = new SelectList(movieDropdownData.Producers, "Id", "FullName");
            ViewBag.Characters = new SelectList(movieDropdownData.Characters, "Id", "FullName");

            return View(movie);
        }

        await _service.AddNewMovieAsync(movie);
        return RedirectToAction(nameof(Index));
    }

    //Get: Movies/Edit

    public async Task<IActionResult> Edit(int id)
    {
        var movieDetails = await _service.GetMovieByIdAsync(id);
        if (movieDetails == null) return View("NotFound");

        var result = new NewMovieVM()
        {
            Id = movieDetails.Id,
            Name = movieDetails.Name,
            Description = movieDetails.Description,
            Price = movieDetails.Price,
            StartDate = movieDetails.StartDate,
            EndDate = movieDetails.EndDate,
            ImageURL = movieDetails.ImageURL,
            MovieCategory = movieDetails.MovieCategory,
            CinemaId = movieDetails.CinemaId,
            ProducerId = movieDetails.ProducerId,
            CharacterIds = movieDetails.Character_Movies.Select(n => n.CharacterId).ToList(),

        };

        var movieDropdownData = await _service.GetMovieDropdownsValues();
        ViewBag.Cinemas = new SelectList(movieDropdownData.Cinemas, "Id", "Name");
        ViewBag.Producers = new SelectList(movieDropdownData.Producers, "Id", "FullName");
        ViewBag.Characters = new SelectList(movieDropdownData.Characters, "Id", "FullName");
        return View(result);

    }

    [HttpPost]
    public async Task<IActionResult> Edit(int id, NewMovieVM movie)
    {
        if (id != movie.Id) return View("NotFound");

        if (!ModelState.IsValid)
        {
            var movieDropdownsData = await _service.GetMovieDropdownsValues();

            ViewBag.Cinemas = new SelectList(movieDropdownsData.Cinemas, "Id", "Name");
            ViewBag.Producers = new SelectList(movieDropdownsData.Producers, "Id", "FullName");
            ViewBag.Actors = new SelectList(movieDropdownsData.Characters, "Id", "FullName");

            return View(movie);
        }

        await _service.UpdateMovieAsync(movie);
        return RedirectToAction(nameof(Index));
    }
}
