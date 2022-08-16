using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;

namespace AnimeTickets.Models;

public class ApplicationUser: IdentityUser
{
    [Display(Name = "Full name")]
    public string FullName { get; set; }
    
}