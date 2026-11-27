// See https://aka.ms/new-console-template for more information

using ProductExceptSelf;

Solution  solution = new Solution();
int [] ans = solution.ProductExceptSelf([1,2,3,4,5]);
foreach(int i in ans)
{
    Console.Write($"{i} ");
}