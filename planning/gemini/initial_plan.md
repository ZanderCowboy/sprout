https://gemini.google.com/app/e8e73f69af7fc9e2

generate a command that i can give to Cursor to plan a Flutter app. 



Purpose: I'd like to be able to have a quick view of my current savings goals and make amendments as needed. 



UX Requirements:

- I'd like there to be tabs at the bottom of the home page where you can switch between views. The tabs are Home, a center + button, and Goals.

- Initially, on the home page you will see the total monetary value that we currently have. It needs to be in south african rands. there can be different accounts listed below the total value.

- if you press the + button, you can add a new goals, or you can "deposit" more money. 

- if you deposit more money, you need to be able to select which account it needs to be added to and for which goal is it. 

- you can have multiple accounts like a 32-day notice account or a 24 hour notice account etc. The name of the accounts can be customised. 

- if you go to the goals view, you can have a clear view of all your active goals. like Car Deposit or Discovery Savings etc. You can also customize the name. 

- there needs to be basic functionality added to like CRUD. 

- there is an indication beneath the total value of when it was last updated. 

- For the goals: we need to have a progress bar with a percentage value to indicate the progress for that particular goal. We also need to show the value that we still need to go. 

- When you click on an account, you can see all the transactions or "deposits" that was made with the date and for which goal it is. The same for goals. 



UI:

- Every account/goal needs to be in a card, with a color. The app should be vivid and colourful. 

- The look should be premium and neat. 



Data Storage: 

- We need to set up local storage. (What DB should we use?)

- We need to link to Firebase as well. There is a strong preference to store the data remotely and not locally. (Is Firebase the best option? What about Supabase?)



Strict Architecture Requirements:

- We need to use BLoC 

- Do not mix logic and UI. Keep a clear separation

- Use constants where possible.

- Use ENUMS as much as possible 

- Use services where possible.

- Data calls: UI -> Bloc -> Serice -> Repo -> Data Source

- Preference to use Application, Domain, and Data layers 

- Follow Clean Architecture Principles. 

- Use proper exception handling



======

Please refine and ask any questions necessary. 