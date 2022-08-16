using AnimeTickets.Models.Static;
using Microsoft.AspNetCore.Identity;

namespace AnimeTickets.Models;

public class AppDbInitializer
{
    public static void Seed(IApplicationBuilder applicationBuilder)
    {
        using (var serviceScope = applicationBuilder.ApplicationServices.CreateScope())
        {
            var context = serviceScope.ServiceProvider.GetService<AppDbContext>();
            context.Database.EnsureCreated();
            if (!context.Cinema.Any())
            {
                context.Cinema.AddRange(new List<Cinema>()
                {
                    new Cinema()
                    {
                        Logo = "https://i.pinimg.com/474x/7a/7f/49/7a7f497ee08b124d479ecc7688944d8a.jpg",
                        Name = "Cinema 1",
                        Description = "Description of the first cinema"
                    },
                    new Cinema()
                    {
                        Logo = "https://cdn.dribbble.com/users/4017506/screenshots/9716589/cinema_logo_4x.png",
                        Name = "Cinema 2",
                        Description = "Description of the second cinema"
                    },
                    new Cinema()
                    {
                        Logo = "https://img.freepik.com/premium-vector/cinema-logo-design-template_92405-24.jpg?w=2000",
                        Name = "Cinema 3",
                        Description = "Description of the third cinema"
                    }
                });
                context.SaveChanges();
            }
            if (!context.Characters.Any())
            {
                context.Characters.AddRange(new List<Character>()
                {
                    new Character()
                    {
                        ProfilePictureURL = "https://static.wikia.nocookie.net/violet-evergarden/images/a/ae/Violet_Evergarden.png/revision/latest/scale-to-width-down/700?cb=20180209195829",
                        FullName = "Violet Evergarden",
                        Bio = "Violet Evergarden (ヴァイオレット・エヴァーガーデン, Vaioretto Evāgāden?) is the protagonist of the Violet Evergarden series. Violet is a former soldier who was enlisted in the Leidenschaftlich army and fought in the war, where she was treated as nothing more than a weapon. "
                    },
                    new Character()
                    {
                        ProfilePictureURL = "https://static.wikia.nocookie.net/violet-evergarden/images/9/9c/Cattleya_Baudelaire_%28Anime%29.png/revision/latest/top-crop/width/360/height/360?cb=20180112200807",
                        FullName = "Cattleya Baudelaire",
                        Bio = "Cattleya Baudelaire (カトレア・ボードレール, Katorea Bōdorēru?) is a character in the Violet Evergarden series. Being a figurehead Auto Memories Doll who works for the CH Postal Company, Cattleya never stops being requested and often takes on clients with love troubles. She works alongside Violet and has been close with Hodgins since before the company was established, joining as one of its initial employees."
                    },
                    new Character()
                    {
                        ProfilePictureURL = "https://static.wikia.nocookie.net/kimetsu-no-yaiba/images/a/aa/Kagaya_anime.png/revision/latest?cb=20200303193448",
                        FullName = "Kagaya Ubuyashiki ",
                        Bio = "Cattleya Baudelaire (カトレア・ボードレール, Katorea Bōdorēru?) is a character in the Violet Evergarden series. Being a figurehead Auto Memories Doll who works for the CH Postal Company, Cattleya never stops being requested and often takes on clients with love troubles. She works alongside Violet and has been close with Hodgins since before the company was established, joining as one of its initial employees."
                    },
                    new Character()
                    {
                        ProfilePictureURL = "https://static.wikia.nocookie.net/kimetsu-no-yaiba/images/8/88/Hinaki_anime.png/revision/latest?cb=20191022130545",
                        FullName = "Hinaki Ubuyashiki",
                        Bio = "Cattleya Baudelaire (カトレア・ボードレール, Katorea Bōdorēru?) is a character in the Violet Evergarden series. Being a figurehead Auto Memories Doll who works for the CH Postal Company, Cattleya never stops being requested and often takes on clients with love troubles. She works alongside Violet and has been close with Hodgins since before the company was established, joining as one of its initial employees."
                    },
                    new Character()
                    {
                        ProfilePictureURL = "https://static.wikia.nocookie.net/kimetsu-no-yaiba/images/e/e5/Shinobu_anime.png/revision/latest/scale-to-width-down/700?cb=20211119011810",
                        FullName = "Shinobu Kocho",
                        Bio = "Cattleya Baudelaire (カトレア・ボードレール, Katorea Bōdorēru?) is a character in the Violet Evergarden series. Being a figurehead Auto Memories Doll who works for the CH Postal Company, Cattleya never stops being requested and often takes on clients with love troubles. She works alongside Violet and has been close with Hodgins since before the company was established, joining as one of its initial employees."
                    }
                });
                context.SaveChanges();
            }
            if (!context.Producers.Any())
            {
                context.Producers.AddRange(new List<Producer>()
                {
                    new Producer()
                    {
                        FullName = "Producer 1",
                        Bio = "This is the Bio of the first actor",
                        ProfilePictureURL = "http://dotnethow.net/images/producers/producer-1.jpeg"

                    },
                    new Producer()
                    {
                        FullName = "Producer 2",
                        Bio = "This is the Bio of the second actor",
                        ProfilePictureURL = "http://dotnethow.net/images/producers/producer-2.jpeg"
                    },
                    new Producer()
                    {
                        FullName = "Producer 3",
                        Bio = "This is the Bio of the second actor",
                        ProfilePictureURL = "http://dotnethow.net/images/producers/producer-3.jpeg"
                    },
                    new Producer()
                    {
                        FullName = "Producer 4",
                        Bio = "This is the Bio of the second actor",
                        ProfilePictureURL = "http://dotnethow.net/images/producers/producer-4.jpeg"
                    },
                    new Producer()
                    {
                        FullName = "Producer 5",
                        Bio = "This is the Bio of the second actor",
                        ProfilePictureURL = "http://dotnethow.net/images/producers/producer-5.jpeg"
                    }
                });
                context.SaveChanges();
                
            }
            if (!context.Movies.Any())
            {
                 context.Movies.AddRange(new List<Movie>()
                    {
                        new Movie()
                        {
                            Name = "Violet Evergarden",
                            Description = "Violet Evergarden: The Movie (Japanese: 劇場版 ヴァイオレット・エヴァーガーデン, Hepburn: Gekijōban Vaioretto Evāgāden) is a 2020 Japanese animated film based on Violet Evergarden light novel series by Kana Akatsuki and a sequel to Violet Evergarden (2018). Produced by Kyoto Animation and distributed by Shochiku, the film is directed by Taichi Ishidate from a script written by Reiko Yoshida, and stars Yui Ishikawa and Daisuke Namikawa. In the film, Violet Evergarden continues in her search for the meaning of the final words left by Gilbert Bougainvillea when she receives a request to write a letter from a boy named Yuris.",
                            Price = 39.50,
                            ImageURL = "https://upload.wikimedia.org/wikipedia/en/9/96/Violet_Evergarden_the_Movie_poster.jpg",
                            StartDate = DateTime.Now.AddDays(-10),
                            EndDate = DateTime.Now.AddDays(10),
                            CinemaId = 3,
                            ProducerId = 3,
                            MovieCategory = MovieCategory.Drama
                        },
                        new Movie()
                        {
                            Name = "Neon Genesis Evangelion",
                            Description = "The End of Evangelion (Japanese: 新世紀エヴァンゲリオン劇場版 Air/まごころを、君に, Hepburn: Shin Seiki Evangerion Gekijō-ban: Ea/Magokoro o, Kimi ni, lit. 'Neon Genesis Evangelion Theatrical Edition: Air/Sincerely Yours') is a 1997 Japanese animated apocalyptic psychological drama film written by Hideaki Anno, co-directed by Anno and Kazuya Tsurumaki, and animated by Gainax and Production I.G. The film serves as a parallel ending to the anime television series Neon Genesis Evangelion, which aired from 1995–1996 and ended with two episodes that became controversial.",
                            Price = 29.50,
                            ImageURL = "http://dotnethow.net/images/movies/movie-1.jpeg",
                            StartDate = DateTime.Now,
                            EndDate = DateTime.Now.AddDays(3),
                            CinemaId = 1,
                            ProducerId = 1,
                            MovieCategory = MovieCategory.Comedy
                        },
                        new Movie()
                        {
                            Name = "The End of Evangelion",
                            Description = "The End of Evangelion (Japanese: 新世紀エヴァンゲリオン劇場版 Air/まごころを、君に, Hepburn: Shin Seiki Evangerion Gekijō-ban: Ea/Magokoro o, Kimi ni, lit. 'Neon Genesis Evangelion Theatrical Edition: Air/Sincerely Yours') is a 1997 Japanese animated apocalyptic psychological drama film written by Hideaki Anno, co-directed by Anno and Kazuya Tsurumaki, and animated by Gainax and Production I.G. The film serves as a parallel ending to the anime television series Neon Genesis Evangelion, which aired from 1995–1996 and ended with two episodes that became controversial.",
                            Price = 39.50,
                            ImageURL = "https://upload.wikimedia.org/wikipedia/en/9/9e/Eoeposter.JPG",
                            StartDate = DateTime.Now,
                            EndDate = DateTime.Now.AddDays(7),
                            CinemaId = 2,
                            ProducerId = 4,
                            MovieCategory = MovieCategory.Fantasy
                        },
                        new Movie()
                        {
                            Name = "A Whisker Away",
                            Description = "The End of Evangelion (Japanese: 新世紀エヴァンゲリオン劇場版 Air/まごころを、君に, Hepburn: Shin Seiki Evangerion Gekijō-ban: Ea/Magokoro o, Kimi ni, lit. 'Neon Genesis Evangelion Theatrical Edition: Air/Sincerely Yours') is a 1997 Japanese animated apocalyptic psychological drama film written by Hideaki Anno, co-directed by Anno and Kazuya Tsurumaki, and animated by Gainax and Production I.G. The film serves as a parallel ending to the anime television series Neon Genesis Evangelion, which aired from 1995–1996 and ended with two episodes that became controversial.",
                            Price = 39.50,
                            ImageURL = "https://upload.wikimedia.org/wikipedia/en/d/df/Nakitai_Watashi_wa_Neko_o_Kaburu_poster.png",
                            StartDate = DateTime.Now.AddDays(-10),
                            EndDate = DateTime.Now.AddDays(-5),
                            CinemaId = 1,
                            ProducerId = 2,
                            MovieCategory = MovieCategory.Romance
                        },
                        new Movie()
                        {
                            Name = "Flavors of Youth",
                            Description = "The End of Evangelion (Japanese: 新世紀エヴァンゲリオン劇場版 Air/まごころを、君に, Hepburn: Shin Seiki Evangerion Gekijō-ban: Ea/Magokoro o, Kimi ni, lit. 'Neon Genesis Evangelion Theatrical Edition: Air/Sincerely Yours') is a 1997 Japanese animated apocalyptic psychological drama film written by Hideaki Anno, co-directed by Anno and Kazuya Tsurumaki, and animated by Gainax and Production I.G. The film serves as a parallel ending to the anime television series Neon Genesis Evangelion, which aired from 1995–1996 and ended with two episodes that became controversial.",
                            Price = 39.50,
                            ImageURL = "https://upload.wikimedia.org/wikipedia/en/c/c6/Flavors_of_Youth_poster.jpeg",
                            StartDate = DateTime.Now.AddDays(-10),
                            EndDate = DateTime.Now.AddDays(-2),
                            CinemaId = 1,
                            ProducerId = 3,
                            MovieCategory = MovieCategory.Drama
                        },
                        new Movie()
                        {
                            Name = "The Seven Deadly Sins",
                            Description = "The End of Evangelion (Japanese: 新世紀エヴァンゲリオン劇場版 Air/まごころを、君に, Hepburn: Shin Seiki Evangerion Gekijō-ban: Ea/Magokoro o, Kimi ni, lit. 'Neon Genesis Evangelion Theatrical Edition: Air/Sincerely Yours') is a 1997 Japanese animated apocalyptic psychological drama film written by Hideaki Anno, co-directed by Anno and Kazuya Tsurumaki, and animated by Gainax and Production I.G. The film serves as a parallel ending to the anime television series Neon Genesis Evangelion, which aired from 1995–1996 and ended with two episodes that became controversial.",
                            Price = 39.50,
                            ImageURL = "https://upload.wikimedia.org/wikipedia/en/4/43/Seven_Deadly_Sins_Movie.jpg",
                            StartDate = DateTime.Now.AddDays(3),
                            EndDate = DateTime.Now.AddDays(20),
                            CinemaId = 1,
                            ProducerId = 5,
                            MovieCategory = MovieCategory.Drama
                        }
                    });
                    context.SaveChanges();
                
            }
            if (!context.Character_Movies.Any())
            {
                 context.Character_Movies.AddRange(new List<Character_Movie>()
                    {
                        new Character_Movie()
                        {
                            CharacterId = 1,
                            MovieId = 4
                        },
                        new Character_Movie()
                        {
                            CharacterId = 3,
                            MovieId = 4
                        },

                        new Character_Movie()
                        {
                            CharacterId = 1,
                            MovieId = 5
                        },
                        new Character_Movie()
                        {
                            CharacterId = 4,
                            MovieId = 5
                        },

                        new Character_Movie()
                        {
                            CharacterId = 1,
                            MovieId = 6
                        },
                        new Character_Movie()
                        {
                            CharacterId = 2,
                            MovieId = 6
                        },
                        new Character_Movie()
                        {
                            CharacterId = 5,
                            MovieId = 6
                        },
                        new Character_Movie()
                        {
                            CharacterId = 2,
                            MovieId = 7
                        },
                        new Character_Movie()
                        {
                            CharacterId = 3,
                            MovieId = 7
                        },
                        new Character_Movie()
                        {
                            CharacterId = 4,
                            MovieId = 7
                        },
                        new Character_Movie()
                        {
                            CharacterId = 2,
                            MovieId = 8
                        },
                        new Character_Movie()
                        {
                            CharacterId = 3,
                            MovieId = 8
                        },
                        new Character_Movie()
                        {
                            CharacterId = 4,
                            MovieId = 8
                        },
                        new Character_Movie()
                        {
                            CharacterId = 5,
                            MovieId = 8
                        },


                        new Character_Movie()
                        {
                            CharacterId = 3,
                            MovieId = 9
                        },
                        new Character_Movie()
                        {
                            CharacterId = 4,
                            MovieId = 9
                        },
                        new Character_Movie()
                        {
                            CharacterId = 5,
                            MovieId = 9
                        }
                    });
                    context.SaveChanges();
                
            }
        }
    }

    public static async Task SeedUSersAndRoles(IApplicationBuilder applicationBuilder)
    {
        using (var serviceScope = applicationBuilder.ApplicationServices.CreateScope())
        {
            //roles
            var roleManager = serviceScope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
            if (!await roleManager.RoleExistsAsync(UserRoles.Admin))
                await roleManager.CreateAsync(new IdentityRole(UserRoles.Admin));
            if (!await roleManager.RoleExistsAsync(UserRoles.User))
                await roleManager.CreateAsync(new IdentityRole(UserRoles.User));
            
            //users
            var userManager = serviceScope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
            string adminUserEmail = "admin@gmail.com";
            var adminUser = await userManager.FindByEmailAsync(adminUserEmail);
            if (adminUser == null)
            {
                var newAdimUser = new ApplicationUser()
                {
                    FullName = "Admin User",
                    UserName = "Admin",
                    Email = adminUserEmail,
                    EmailConfirmed = true
                };
                await userManager.CreateAsync(newAdimUser, "Pass123.");
                await userManager.AddToRoleAsync(newAdimUser, UserRoles.Admin);
            }
            
           
            string appUserEmail = "user@gmail.com";
            var appUser = await userManager.FindByEmailAsync(appUserEmail);
            if (appUser == null)
            {
                var newAppUser = new ApplicationUser()
                {
                    FullName = "App User",
                    UserName = "App-user",
                    Email = appUserEmail,
                    EmailConfirmed = true
                };
                await userManager.CreateAsync(newAppUser, "Pass123.");
                await userManager.AddToRoleAsync(newAppUser, UserRoles.User);
            }
        }
    }

}